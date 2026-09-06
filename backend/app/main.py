"""FastAPI application exposing the agentic endpoint.

Error-handling contract:
  * 400 — validation errors (IP/port/string) -> ``ErrorResponse``
  * 500 — internal agent failures -> ``ErrorResponse``
"""

from __future__ import annotations

import asyncio
import base64
import ipaddress
import re
import time
from typing import Any, List
from urllib.parse import urlsplit

import httpx
from fastapi import FastAPI, File, Header, HTTPException, Query, Request, UploadFile
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from langchain.agents import AgentExecutor
from starlette.middleware.cors import CORSMiddleware

from .agent import build_agent_executor, extract_tools_used
from .config import get_settings
from .exploitdb import ExploitDbError, search as search_exploitdb
from .models import (
    AgentRequest,
    AgentResponse,
    CodeBlock,
    ErrorDetail,
    ErrorResponse,
    new_session_id,
)
from .virustotal import VirusTotalClient, VirusTotalError

app = FastAPI(
    title="PayloadHub-AI Backend",
    version="1.0.0",
    description="Deterministic agentic penetration-testing assistant (ethical use only).",
)

_cors_origins = [origin.strip() for origin in get_settings().cors_allow_origins.split(",") if origin.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins or ["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

_agent_executor: AgentExecutor | None = None

_CODE_FENCE_RE = re.compile(r"```([A-Za-z0-9_+.-]*)\n?(.*?)```", re.DOTALL)


def get_agent_executor() -> AgentExecutor:
    """Lazily build and cache the agent executor."""
    global _agent_executor
    if _agent_executor is None:
        _agent_executor = build_agent_executor(get_settings())
    return _agent_executor


def _extract_code_blocks(text: str) -> List[CodeBlock]:
    """Pull markdown fenced code blocks out of the agent's final answer."""
    blocks: List[CodeBlock] = []
    for match in _CODE_FENCE_RE.finditer(text or ""):
        language = (match.group(1) or "text").strip() or "text"
        code = match.group(2).strip("\n")
        if code:
            blocks.append(CodeBlock(language=language, code=code))
    return blocks


@app.exception_handler(RequestValidationError)
async def _validation_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    """Map pydantic validation failures to a 400 with a structured envelope."""
    details = [
        ErrorDetail(
            loc=[str(item) for item in (err.get("loc") or [])],
            msg=str(err.get("msg", "validation error")),
            type=str(err.get("type", "value_error")),
        )
        for err in exc.errors()
    ]
    return JSONResponse(status_code=400, content=ErrorResponse(detail=details).model_dump())


@app.post(
    "/api/v1/agent/execute",
    response_model=AgentResponse,
    responses={
        400: {"model": ErrorResponse, "description": "Validation error"},
        500: {"model": ErrorResponse, "description": "Internal agent error"},
    },
)
async def execute_agent(request: AgentRequest) -> AgentResponse:
    """Run the agent pipeline against the validated request."""
    session_id = request.session_id or new_session_id()
    started = time.monotonic()

    try:
        agent = get_agent_executor()
        prompt = request.build_prompt()
        # Run the blocking LangChain executor off the event loop.
        raw_result: dict[str, Any] = await asyncio.to_thread(
            agent.invoke,
            {"input": prompt, "chat_history": []},
        )

        output: str = raw_result.get("output") or ""
        tools_used = extract_tools_used(raw_result)

        return AgentResponse(
            session_id=session_id,
            response=output,
            code_blocks=_extract_code_blocks(output),
            tools_used=tools_used,
            elapsed_ms=int((time.monotonic() - started) * 1000),
        )
    except Exception as exc:  # noqa: BLE001 — surface any internal failure as 500
        detail = [ErrorDetail(loc=["body"], msg=f"internal agent error: {exc}", type="agent_error")]
        return JSONResponse(status_code=500, content=ErrorResponse(detail=detail).model_dump())


def _virus_total_client(api_key: str | None) -> VirusTotalClient:
    settings = get_settings()
    key = (api_key or settings.virustotal_api_key).strip()
    if not key:
        raise HTTPException(
            status_code=503,
            detail="VirusTotal API key belum dikonfigurasi. Isi Settings atau VIRUSTOTAL_API_KEY.",
        )
    return VirusTotalClient(key, settings.virustotal_base_url, settings.request_timeout_seconds)


def _safe_url(value: str) -> str:
    url = value.strip()
    parsed = urlsplit(url)
    if parsed.scheme.lower() not in {"http", "https"} or not parsed.hostname:
        raise HTTPException(status_code=400, detail="URL harus memakai skema http atau https.")
    if parsed.username or parsed.password:
        raise HTTPException(status_code=400, detail="URL dengan username/password tidak didukung.")
    if len(url) > 2048:
        raise HTTPException(status_code=400, detail="URL terlalu panjang (maksimum 2048 karakter).")
    return url


def _url_id(url: str) -> str:
    return base64.urlsafe_b64encode(url.encode("utf-8")).decode("ascii").rstrip("=")


async def _vt_request(operation):
    try:
        return await operation
    except VirusTotalError as exc:
        raise HTTPException(status_code=exc.status_code, detail=str(exc)) from exc
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=502,
            detail="VirusTotal tidak dapat dihubungi. Periksa koneksi backend lalu coba lagi.",
        ) from exc


@app.get("/api/v1/exploitdb/search")
async def exploitdb_search(
    q: str = Query(..., min_length=1, max_length=120),
    limit: int = Query(default=20, ge=1, le=50),
) -> dict[str, Any]:
    """Search the official ExploitDB catalogue without executing any PoC."""
    settings = get_settings()
    query = q.strip()
    if not query:
        raise HTTPException(status_code=400, detail="Query ExploitDB tidak boleh kosong.")
    try:
        return await asyncio.to_thread(
            search_exploitdb, query, settings.exploitdb_csv_url, settings.exploitdb_cache_seconds, limit
        )
    except ExploitDbError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@app.get("/api/v1/virustotal/status")
async def virustotal_status(
    x_virustotal_api_key: str | None = Header(default=None),
) -> dict[str, Any]:
    return {"configured": bool((x_virustotal_api_key or get_settings().virustotal_api_key).strip())}


@app.post("/api/v1/virustotal/urls")
async def virustotal_scan_url(
    payload: dict[str, Any],
    x_virustotal_api_key: str | None = Header(default=None),
) -> dict[str, Any]:
    url_value = payload.get("url") if isinstance(payload, dict) else None
    if not isinstance(url_value, str) or not url_value.strip():
        raise HTTPException(status_code=400, detail="Field url wajib diisi.")
    url = _safe_url(url_value)
    client = _virus_total_client(x_virustotal_api_key)
    return await _vt_request(client.submit_url(url))


@app.post("/api/v1/virustotal/files")
async def virustotal_scan_file(
    file: UploadFile = File(...),
    x_virustotal_api_key: str | None = Header(default=None),
) -> dict[str, Any]:
    settings = get_settings()
    file.file.seek(0, 2)
    size = file.file.tell()
    await file.seek(0)
    if size <= 0:
        raise HTTPException(status_code=400, detail="File kosong tidak dapat dipindai.")
    if size > settings.virustotal_max_file_bytes:
        limit_mb = settings.virustotal_max_file_bytes // (1024 * 1024)
        raise HTTPException(status_code=413, detail=f"Ukuran file melebihi batas {limit_mb} MB.")
    client = _virus_total_client(x_virustotal_api_key)
    return await _vt_request(client.submit_file(file.file, file.filename or "upload.bin", file.content_type, size))


@app.get("/api/v1/virustotal/analyses/{analysis_id:path}")
async def virustotal_analysis(
    analysis_id: str,
    kind: str | None = Query(default=None, pattern="^(file|url)$"),
    filename: str | None = Query(default=None, max_length=255),
    x_virustotal_api_key: str | None = Header(default=None),
) -> dict[str, Any]:
    if not re.fullmatch(r"[A-Za-z0-9_+=/:-]{1,512}", analysis_id):
        raise HTTPException(status_code=400, detail="Analysis ID VirusTotal tidak valid.")
    client = _virus_total_client(x_virustotal_api_key)
    return await _vt_request(client.get_analysis(analysis_id, kind=kind, filename=filename))


@app.get("/api/v1/virustotal/files/{file_hash}")
async def virustotal_file_report(
    file_hash: str,
    x_virustotal_api_key: str | None = Header(default=None),
) -> dict[str, Any]:
    if not re.fullmatch(r"[A-Fa-f0-9]{32}|[A-Fa-f0-9]{40}|[A-Fa-f0-9]{64}", file_hash):
        raise HTTPException(status_code=400, detail="Hash file harus MD5, SHA-1, atau SHA-256.")
    client = _virus_total_client(x_virustotal_api_key)
    return await _vt_request(client.get_file_report(file_hash.lower()))


@app.get("/api/v1/virustotal/url-report")
async def virustotal_url_report(
    url: str = Query(..., min_length=1, max_length=2048),
    x_virustotal_api_key: str | None = Header(default=None),
) -> dict[str, Any]:
    safe_url = _safe_url(url)
    client = _virus_total_client(x_virustotal_api_key)
    return await _vt_request(client.get_url_report(_url_id(safe_url)))


@app.get("/api/v1/virustotal/domains/{domain}")
async def virustotal_domain_report(
    domain: str,
    x_virustotal_api_key: str | None = Header(default=None),
) -> dict[str, Any]:
    if len(domain) > 253 or not re.fullmatch(r"[A-Za-z0-9.-]+", domain):
        raise HTTPException(status_code=400, detail="Nama domain tidak valid.")
    client = _virus_total_client(x_virustotal_api_key)
    return await _vt_request(client.get_indicator_report("domains", domain.lower()))


@app.get("/api/v1/virustotal/ips/{ip_address}")
async def virustotal_ip_report(
    ip_address: str,
    x_virustotal_api_key: str | None = Header(default=None),
) -> dict[str, Any]:
    try:
        ipaddress.ip_address(ip_address)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Alamat IP tidak valid.") from exc
    client = _virus_total_client(x_virustotal_api_key)
    return await _vt_request(client.get_indicator_report("ip_addresses", ip_address))


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok"}
