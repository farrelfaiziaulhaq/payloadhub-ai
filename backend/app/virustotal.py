"""Small VirusTotal API v3 client used by the HTTP endpoints.

The client deliberately returns a compact, stable shape to the Flutter app;
raw engine output is reduced to the useful verdict fields and never logged.
"""

from __future__ import annotations

from collections.abc import Mapping
import hashlib
from typing import Any

import httpx
from urllib.parse import quote


class VirusTotalError(Exception):
    def __init__(self, message: str, status_code: int = 502) -> None:
        super().__init__(message)
        self.status_code = status_code


class VirusTotalClient:
    def __init__(self, api_key: str, base_url: str, timeout_seconds: int = 45) -> None:
        self.api_key = api_key.strip()
        self.base_url = base_url.rstrip("/")
        self.timeout = httpx.Timeout(timeout_seconds, connect=15.0)

    def _headers(self) -> dict[str, str]:
        return {"x-apikey": self.api_key, "accept": "application/json"}

    @staticmethod
    def _json(response: httpx.Response) -> dict[str, Any]:
        try:
            value = response.json()
        except ValueError as exc:
            raise VirusTotalError("VirusTotal returned an invalid response.") from exc
        if not isinstance(value, dict):
            raise VirusTotalError("VirusTotal returned an unexpected response.")
        return value

    def _raise_for_status(self, response: httpx.Response) -> None:
        if response.is_success:
            return
        status = response.status_code
        if status in (401, 403):
            raise VirusTotalError("VirusTotal API key ditolak atau tidak memiliki akses.", status)
        if status == 429:
            raise VirusTotalError("Batas request VirusTotal tercapai. Coba lagi nanti.", status)
        detail = ""
        try:
            error = response.json().get("error", {})
            detail = str(error.get("message", "")) if isinstance(error, dict) else ""
        except ValueError:
            pass
        raise VirusTotalError(
            f"VirusTotal request gagal (HTTP {status})" + (f": {detail}" if detail else "."),
            status,
        )

    def _result(
        self,
        data: Mapping[str, Any],
        *,
        kind: str | None = None,
        resource_id: str | None = None,
        filename: str | None = None,
    ) -> dict[str, Any]:
        attributes = data.get("attributes")
        attributes = attributes if isinstance(attributes, Mapping) else {}
        stats = attributes.get("stats") or attributes.get("last_analysis_stats") or {}
        stats = stats if isinstance(stats, Mapping) else {}
        normalized_stats = {
            key: int(stats.get(key, 0) or 0)
            for key in ("malicious", "suspicious", "harmless", "undetected", "timeout")
        }
        detections: list[dict[str, str]] = []
        results = attributes.get("results") or attributes.get("last_analysis_results") or {}
        if isinstance(results, Mapping):
            for engine, value in results.items():
                if not isinstance(value, Mapping):
                    continue
                category = str(value.get("category", "undetected"))
                if category in {"malicious", "suspicious"}:
                    detections.append(
                        {
                            "engine": str(engine),
                            "category": category,
                            "result": str(value.get("result") or category),
                        }
                    )
        detections.sort(key=lambda item: (item["category"] != "malicious", item["engine"]))
        raw_status = attributes.get("status")
        status = str(raw_status) if raw_status else ("queued" if data.get("type") == "analysis" else "completed")
        output: dict[str, Any] = {
            "status": status,
            "kind": kind or str(data.get("type", "")),
            "analysis_id": str(data.get("id", "")),
            "resource_id": resource_id,
            "stats": normalized_stats,
            "detections": detections[:50],
            "malicious": normalized_stats["malicious"] > 0,
            "suspicious": normalized_stats["suspicious"] > 0,
        }
        if filename:
            output["filename"] = filename
        if resource_id:
            gui_kind = {
                "url": "url",
                "file": "file",
                "domains": "domain",
                "ip_addresses": "ip-address",
            }.get(kind or "file", "file")
            output["permalink"] = f"https://www.virustotal.com/gui/{gui_kind}/{resource_id}"
        return output

    async def submit_url(self, url: str) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                f"{self.base_url}/urls",
                headers=self._headers(),
                data={"url": url},
            )
        self._raise_for_status(response)
        body = self._json(response)
        data = body.get("data")
        if not isinstance(data, Mapping):
            raise VirusTotalError("VirusTotal tidak mengembalikan analysis ID.")
        return self._result(data, kind="url")

    async def submit_file(self, upload, filename: str, content_type: str | None, size: int) -> dict[str, Any]:
        if size > 32 * 1024 * 1024:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.base_url}/files/upload_url", headers=self._headers()
                )
            self._raise_for_status(response)
            upload_url = self._json(response).get("data")
            if not isinstance(upload_url, str) or not upload_url:
                raise VirusTotalError("VirusTotal tidak mengembalikan upload URL.")
        else:
            upload_url = f"{self.base_url}/files"

        # FastAPI passes ``UploadFile.file`` here, which is a synchronous
        # SpooledTemporaryFile. Awaiting its seek() raises TypeError and turns
        # an otherwise valid upload into a generic HTTP 500.
        upload.seek(0)
        files = {"file": (filename or "upload.bin", upload, content_type or "application/octet-stream")}
        async with httpx.AsyncClient(timeout=httpx.Timeout(180.0, connect=15.0)) as client:
            response = await client.post(upload_url, headers=self._headers(), files=files)
        if response.status_code == 409:
            error = self._json(response).get("error", {})
            if isinstance(error, Mapping) and error.get("code") == "AlreadySubmittedError":
                # VirusTotal rejects a duplicate upload while the same hash is
                # already being scanned. Use the hash report instead of
                # surfacing a false upload failure to the dashboard.
                upload.seek(0)
                digest = hashlib.sha256()
                while chunk := upload.read(1024 * 1024):
                    digest.update(chunk)
                upload.seek(0)
                try:
                    result = await self.get_file_report(digest.hexdigest())
                    result["filename"] = filename
                    return result
                except VirusTotalError as exc:
                    if exc.status_code != 404:
                        raise
        self._raise_for_status(response)
        body = self._json(response)
        data = body.get("data")
        if not isinstance(data, Mapping):
            raise VirusTotalError("VirusTotal tidak mengembalikan analysis ID.")
        return self._result(data, kind="file", filename=filename)

    async def get_analysis(self, analysis_id: str, kind: str | None = None, filename: str | None = None) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/analyses/{quote(analysis_id, safe='')}", headers=self._headers()
            )
        self._raise_for_status(response)
        data = self._json(response).get("data")
        if not isinstance(data, Mapping):
            raise VirusTotalError("VirusTotal returned no analysis data.")
        return self._result(data, kind=kind, filename=filename)

    async def get_file_report(self, file_hash: str) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/files/{file_hash}", headers=self._headers()
            )
        self._raise_for_status(response)
        data = self._json(response).get("data")
        if not isinstance(data, Mapping):
            raise VirusTotalError("VirusTotal returned no file report.")
        return self._result(data, kind="file", resource_id=file_hash)

    async def get_url_report(self, url_id: str) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/urls/{url_id}", headers=self._headers()
            )
        self._raise_for_status(response)
        data = self._json(response).get("data")
        if not isinstance(data, Mapping):
            raise VirusTotalError("VirusTotal returned no URL report.")
        return self._result(data, kind="url", resource_id=url_id)

    async def get_indicator_report(self, kind: str, indicator: str) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/{kind}/{indicator}", headers=self._headers()
            )
        self._raise_for_status(response)
        data = self._json(response).get("data")
        if not isinstance(data, Mapping):
            raise VirusTotalError("VirusTotal returned no indicator report.")
        return self._result(data, kind=kind, resource_id=indicator)
