"""Application configuration loaded from environment variables.

All secrets live server-side (or are injected by the deployment platform).
The LLM API key is *never* sent to the mobile client.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv

load_dotenv()


def _load_virustotal_key() -> str:
    """Read VT key from env first, then from the local project key file.

    The file fallback is intended for this local development setup only. It is
    deliberately server-side and is never added to Flutter assets.
    """
    configured = os.getenv("VIRUSTOTAL_API_KEY", "").strip()
    if configured:
        return configured

    project_root = Path(__file__).resolve().parents[2]
    for filename in ("api-virustotal", "key-virustotal", "key-virus-total"):
        key_file = project_root / filename
        try:
            key = key_file.read_text(encoding="utf-8").strip()
        except OSError:
            continue
        if key:
            return key
    return ""


@dataclass(frozen=True)
class Settings:
    """Runtime settings for the PayloadHub-AI backend."""

    llm_api_key: str = field(default_factory=lambda: os.getenv("LLM_API_KEY", ""))
    llm_model: str = field(default_factory=lambda: os.getenv("LLM_MODEL", "gpt-4o-mini"))
    llm_base_url: Optional[str] = field(default_factory=lambda: os.getenv("LLM_BASE_URL") or None)
    llm_temperature: float = field(
        default_factory=lambda: float(os.getenv("LLM_TEMPERATURE", "0.0"))
    )
    llm_max_tokens: int = field(
        default_factory=lambda: int(os.getenv("LLM_MAX_TOKENS", "1024"))
    )
    agent_max_iterations: int = field(
        default_factory=lambda: int(os.getenv("AGENT_MAX_ITERATIONS", "8"))
    )
    agent_timeout_seconds: int = field(
        default_factory=lambda: int(os.getenv("AGENT_TIMEOUT_SECONDS", "60"))
    )
    request_timeout_seconds: int = field(
        default_factory=lambda: int(os.getenv("LLM_REQUEST_TIMEOUT_SECONDS", "45"))
    )
    # VirusTotal is proxied by the backend so the key is never bundled into
    # the Flutter application. A per-request X-VirusTotal-API-Key header may
    # still be supplied by the client for local/development use.
    virustotal_api_key: str = field(
        default_factory=_load_virustotal_key
    )
    virustotal_base_url: str = field(
        default_factory=lambda: os.getenv(
            "VIRUSTOTAL_BASE_URL", "https://www.virustotal.com/api/v3"
        ).rstrip("/")
    )
    virustotal_max_file_bytes: int = field(
        default_factory=lambda: int(os.getenv("VIRUSTOTAL_MAX_FILE_BYTES", str(650 * 1024 * 1024)))
    )
    exploitdb_csv_url: str = field(
        default_factory=lambda: os.getenv(
            "EXPLOITDB_CSV_URL",
            "https://gitlab.com/exploit-database/exploitdb/-/raw/main/files_exploits.csv",
        )
    )
    exploitdb_cache_seconds: int = field(
        default_factory=lambda: int(os.getenv("EXPLOITDB_CACHE_SECONDS", "3600"))
    )
    cors_allow_origins: str = field(
        default_factory=lambda: os.getenv("CORS_ALLOW_ORIGINS", "*")
    )


def get_settings() -> Settings:
    """Return a (cached) settings instance."""
    return _SETTINGS


_SETTINGS = Settings()
