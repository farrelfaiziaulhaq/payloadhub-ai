"""Record real Flutter UI interactions and encode a captioned portrait MP4.

Requires playwright (Chrome installed), imageio-ffmpeg, and Pillow.
Run after `flutter build web --release`: python docs/tools/record_demo.py
"""

from __future__ import annotations

import functools
import http.server
import json
from pathlib import Path
import subprocess
import threading
import time

import imageio_ffmpeg
from PIL import Image
from playwright.sync_api import sync_playwright


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "demo"


def stamp(seconds: float) -> str:
    milliseconds = max(0, round(seconds * 1000))
    hours, milliseconds = divmod(milliseconds, 3600000)
    minutes, milliseconds = divmod(milliseconds, 60000)
    seconds_int, milliseconds = divmod(milliseconds, 1000)
    return f"{hours:02}:{minutes:02}:{seconds_int:02},{milliseconds:03}"


def main() -> None:
    web = ROOT / "frontend" / "build" / "web"
    if not (web / "index.html").exists():
        raise FileNotFoundError("Run flutter build web --release first")
    OUT.mkdir(parents=True, exist_ok=True)
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(web))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    url = f"http://127.0.0.1:{server.server_port}"
    cues: list[tuple[float, str]] = []
    try:
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(channel="chrome", headless=True)
            context = browser.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=1)
            page = context.new_page()
            page.goto(url, wait_until="networkidle")
            page.wait_for_timeout(9000)
            # Recording starts only after Flutter has loaded. No fake UI or
            # injected application data is used; history is created by clicks.
            context.close()
            context = browser.new_context(
                viewport={"width": 390, "height": 844},
                device_scale_factor=1,
                record_video_dir=str(OUT / "raw"),
                record_video_size={"width": 390, "height": 844},
            )
            page = context.new_page()
            started = time.monotonic()
            page.goto(url, wait_until="networkidle")
            page.wait_for_timeout(8000)
            trim_start = time.monotonic() - started

            def cue(text: str) -> None:
                cues.append((time.monotonic() - started - trim_start, text))

            def pause(seconds: float) -> None:
                page.mouse.move(5, 410)
                page.wait_for_timeout(seconds * 1000)

            cue("PayloadHub-AI | Demo langsung\nFlutter dalam browser, viewport mobile 390 x 844")
            page.screenshot(path=str(OUT / "check-home.png"))
            pause(5)
            cue("Beranda mobile\nHeader aplikasi, alat cepat, dan navigasi bawah")
            page.mouse.move(200, 600)
            page.mouse.wheel(0, 260)
            pause(4)
            cue("Script Generator\nMembuat payload deterministik tanpa backend AI")
            page.mouse.click(195, 812)
            pause(4)
            cue("Validasi input\nField kosong ditolak sebelum payload dibuat")
            page.mouse.click(195, 553)
            pause(4)
            page.screenshot(path=str(OUT / "check-validation.png"))
            # Reload clears the form validation layout, not the app data.
            page.reload(wait_until="networkidle")
            pause(3)
            page.mouse.click(195, 812)
            pause(1)
            cue("Masukkan konfigurasi lab\nLHOST 10.10.14.8 dan LPORT 9001")
            page.mouse.click(160, 380)
            page.keyboard.type("10.10.14.8", delay=100)
            page.mouse.click(160, 470)
            page.keyboard.type("9001", delay=150)
            pause(2)
            cue("Ketuk Generate\nHasil nyata ditampilkan dan disimpan ke riwayat")
            page.mouse.click(195, 553)
            pause(3)
            page.mouse.move(200, 600)
            page.mouse.wheel(0, 200)
            pause(5)
            page.screenshot(path=str(OUT / "check-result.png"))
            cue("Riwayat Aktivitas\nEntri berasal dari payload yang baru dibuat")
            page.mouse.click(322, 28)
            pause(4)
            page.screenshot(path=str(OUT / "check-history.png"))
            cue("Detail riwayat\nBottom sheet menampilkan payload dan tombol salin")
            page.mouse.click(195, 100)
            pause(4)
            page.mouse.click(28, 28)
            pause(0.6)
            page.mouse.click(28, 28)
            pause(0.8)
            cue("Exploit Library\nKatalog bawaan untuk referensi pengujian berizin")
            page.mouse.click(117, 812)
            pause(4)
            page.mouse.click(195, 160)
            cue("Detail penuh di ponsel\nCVSS, referensi, dan PoC; tidak dieksekusi")
            pause(5)
            page.screenshot(path=str(OUT / "check-detail.png"))
            page.mouse.click(28, 28)
            pause(0.8)
            cue("Setelan aplikasi\nKonfigurasi API dan preferensi tanpa key yang dibundel")
            page.mouse.click(351, 812)
            pause(4)
            page.mouse.click(39, 812)
            pause(1)
            cue("Gunakan hanya pada lab atau target berizin\nDemo UI asli; bukan rekaman perangkat Android fisik")
            pause(5)
            duration = time.monotonic() - started - trim_start
            video = page.video
            context.close()
            if video is None:
                raise RuntimeError("Playwright did not create a recording")
            raw = Path(video.path())
            browser.close()
    finally:
        server.shutdown()
        server.server_close()

    subtitle = OUT / "PayloadHub-AI-Demo.srt"
    entries: list[str] = []
    for index, (start, text) in enumerate(cues):
        end = cues[index + 1][0] if index + 1 < len(cues) else duration
        entries.append(f"{index + 1}\n{stamp(start)} --> {stamp(end)}\n{text}\n")
    subtitle.write_text("\n".join(entries), encoding="utf-8")
    # Caption band lies outside the app, so navigation and form content remain
    # fully visible. Only loading time is trimmed; interactions are real-time.
    ass_filter = (
        "scale=780:1688:flags=lanczos,pad=1080:1920:150:44:color=0x0d1117,"
        "subtitles=PayloadHub-AI-Demo.srt:"
        "force_style='FontName=Arial,FontSize=15,PrimaryColour=&H00FFFFFF,"
        "OutlineColour=&H0017110D,BorderStyle=1,Outline=1,Alignment=2,MarginV=18'"
    )
    target = OUT / "PayloadHub-AI-Demo.mp4"
    subprocess.run(
        [imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-ss", str(trim_start),
         "-i", str(raw), "-t", str(duration), "-vf", ass_filter,
         "-c:v", "libx264", "-preset", "medium", "-crf", "20",
         "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-an", str(target)],
        cwd=OUT, check=True,
    )
    metadata = {
        "file": target.name, "duration_seconds": round(duration, 2),
        "viewport": [390, 844], "output": [1080, 1920],
        "source": "Real Flutter web build in Chrome; not native Android capture",
        "audio": "No audio; Indonesian captions", "raw": str(raw.relative_to(ROOT)),
        "actions": [text for _, text in cues],
    }
    (OUT / "recording.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    main()
