"""Pydantic request/response models with strict validation.

STRICT RULE #3 — Every IP, port, and free-form string is validated and sanitized
*here*, at the FastAPI boundary, before it can reach the LLM or any tool.
"""

from __future__ import annotations

import re
from enum import Enum
from typing import Any, Dict, List, Literal, Optional
from uuid import UUID, uuid4

from pydantic import BaseModel, Field, field_validator, model_validator

# ---------------------------------------------------------------------------
# Strict IPv4 matcher (rejects leading zeros, ranges > 255, and malformed IPs)
# ---------------------------------------------------------------------------
_IPV4_OCTET = r"(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])"
IPV4_PATTERN = re.compile(rf"^(?:{_IPV4_OCTET}\.){{3}}{_IPV4_OCTET}$")

# Characters we allow through after sanitization. This is intentionally narrow:
# printable ASCII plus whitespace/newline. Control characters and unusual
# unicode are stripped to prevent prompt-injection / log-forging tricks.
_SANITIZE_RE = re.compile(r"[^\x20-\x7E\n\r\t]")

_MAX_PROMPT_LEN = 4000
_MAX_SCAN_LEN = 20000
_MAX_TOKEN_LEN = 8000


def is_valid_ipv4(value: str) -> bool:
    """Return True when ``value`` is a strictly valid dotted-quad IPv4."""
    return bool(value) and IPV4_PATTERN.match(value) is not None


def sanitize_text(value: str, max_len: int) -> str:
    """Strip control/unusual characters and clamp the length."""
    cleaned = _SANITIZE_RE.sub("", value).strip()
    return cleaned[:max_len]


class TargetOS(str, Enum):
    linux = "linux"
    windows = "windows"
    unknown = "unknown"


class AgentContext(BaseModel):
    """Optional contextual data attached to a prompt."""

    lhost: Optional[str] = Field(default=None, description="IPv4 listener host")
    lport: Optional[int] = Field(default=None, ge=1, le=65535)
    target: Optional[str] = Field(default=None, description="Target host/IP")
    target_os: TargetOS = Field(default=TargetOS.unknown)
    scan_data: Optional[str] = Field(default=None, description="Raw Nmap/JWT text")

    @field_validator("lhost")
    @classmethod
    def _validate_lhost(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        if not is_valid_ipv4(v):
            raise ValueError("value is not a valid IPv4 address")
        return v

    @field_validator("target")
    @classmethod
    def _sanitize_target(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        return sanitize_text(v, 255)

    @field_validator("scan_data")
    @classmethod
    def _sanitize_scan_data(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        return sanitize_text(v, _MAX_SCAN_LEN)


class AgentRequest(BaseModel):
    """Incoming request from the Flutter client."""

    prompt: str = Field(..., min_length=1, max_length=_MAX_PROMPT_LEN)
    session_id: Optional[UUID] = Field(default=None)
    context: Optional[AgentContext] = Field(default=None)

    @field_validator("prompt")
    @classmethod
    def _sanitize_prompt(cls, v: str) -> str:
        return sanitize_text(v, _MAX_PROMPT_LEN)

    def build_prompt(self) -> str:
        """Compose the final prompt with injected context blocks."""
        parts: List[str] = [self.prompt]
        ctx = self.context
        if ctx is not None:
            if ctx.scan_data:
                parts.append(f"[RAW SCAN DATA]\n{ctx.scan_data}")
            if ctx.target:
                parts.append(f"[TARGET] {ctx.target} (os={ctx.target_os.value})")
            if ctx.lhost and ctx.lport:
                parts.append(f"[LISTENER] lhost={ctx.lhost} lport={ctx.lport}")
        return "\n\n".join(parts)


class CodeBlock(BaseModel):
    """A formatted code block rendered in the Flutter UI."""

    language: str = "text"
    code: str
    payload_type: Optional[str] = None


class AgentResponse(BaseModel):
    """Successful response returned to the Flutter client."""

    status: Literal["success"] = "success"
    session_id: UUID
    response: str
    code_blocks: List[CodeBlock] = Field(default_factory=list)
    tools_used: List[str] = Field(default_factory=list)
    elapsed_ms: int = 0


class ErrorDetail(BaseModel):
    """Single validation error item (mirrors pydantic error shape)."""

    loc: List[Any] = Field(default_factory=list)
    msg: str = "validation error"
    type: str = "value_error"


class ErrorResponse(BaseModel):
    """Uniform error envelope for 400 / 500."""

    status: Literal["error"] = "error"
    detail: List[ErrorDetail] = Field(default_factory=list)


def new_session_id() -> UUID:
    return uuid4()
