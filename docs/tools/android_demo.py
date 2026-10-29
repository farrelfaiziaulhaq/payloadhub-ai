"""Record real APK interactions using adb screenrecord, without exposing keys.

Usage: python docs/tools/android_demo.py
Requires a booted emulator-5556 with the APK installed and backend on port 8000.
Credentials are read only from the ignored backend/.env. Recording starts
after the separately executed provisioning step, never during key entry.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

import imageio_ffmpeg


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "demo"
ADB = Path(os.environ["LOCALAPPDATA"]) / "Android/Sdk/platform-tools/adb.exe"
SERIAL = "emulator-5556"
ACTIVITY = "id.farrel.payloadhubai/com.example.payloadhub_ai.MainActivity"


def adb(*args: str, timeout: float = 45) -> str:
    result = subprocess.run([str(ADB), "-s", SERIAL, *args], capture_output=True,
                            timeout=timeout)
    if result.returncode:
        # Do not print arguments: provisioning can include API credentials.
        raise RuntimeError(f"adb failed ({result.returncode})")
    return result.stdout.decode("utf-8", errors="replace")


def nodes() -> list[ET.Element]:
    adb("shell", "uiautomator", "dump", "/sdcard/demo-ui.xml")
    raw = adb("shell", "cat", "/sdcard/demo-ui.xml")
    return list(ET.fromstring(raw).iter("node"))


def tap_text(text: str) -> None:
    # Flutter can expose bottom destinations with zero accessibility bounds
    # on this emulator. These positions were checked against actual 720x1560
    # screenshots, not inferred from the earlier browser layout.
    navigation = {"Beranda": 72, "Exploit": 216, "Generator": 360,
                  "Monitor": 504, "Setelan": 648}
    if text in navigation:
        adb("shell", "input", "tap", str(navigation[text]), "1390")
        time.sleep(0.7)
        return
    candidates = [n for n in nodes() if text.lower() in
                  (n.get("text", "") + " " + n.get("content-desc", "")).lower()]
    if not candidates:
        raise RuntimeError(f"UI label not visible: {text}")
    bounds = re.findall(r"\d+", candidates[-1].get("bounds", ""))
    if len(bounds) != 4:
        raise RuntimeError("Missing UI bounds")
    x1, y1, x2, y2 = map(int, bounds)
    adb("shell", "input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2))


def screenshot(name: str) -> None:
    adb("shell", "screencap", "-p", "/sdcard/demo-proof.png")
    adb("pull", "/sdcard/demo-proof.png", str(OUT / name))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    # Keep the same phone density while rendering fewer pixels for this
    # memory-constrained host. The APK remains a real Android process.
    if "720x1560" not in adb("shell", "wm", "size"):
        adb("shell", "wm", "size", "720x1560")
    if "293" not in adb("shell", "wm", "density"):
        adb("shell", "wm", "density", "293")

    def tap_design(x: int, y: int) -> None:
        adb("shell", "input", "tap", str(round(x * 2 / 3)), str(round(y * 2 / 3)))
    adb("shell", "am", "start", "-W", "-n", ACTIVITY)
    for _ in range(12):
        if any("Generator" in n.get("content-desc", "") for n in nodes()):
            break
        time.sleep(2)
    else:
        raise RuntimeError("Android app did not become ready; recording not started")
    tap_text("Beranda")
    recorder = subprocess.Popen(
        [str(ADB), "-s", SERIAL, "shell", "screenrecord", "--size", "720x1560",
         "--bit-rate", "4000000", "--time-limit", "150", "/sdcard/payloadhub-demo.mp4"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    started = time.monotonic()
    cues: list[tuple[float, str]] = []

    def cue(text: str, seconds: float = 4) -> None:
        cues.append((time.monotonic() - started, text))
        time.sleep(seconds)

    try:
        cue("APK asli di emulator Android Pixel 5\nRekaman langsung dengan adb screenrecord", 5)
        screenshot("android-home.png")
        tap_text("Generator")
        cue("Generator mobile\nForm tervalidasi dan generator deterministik")
        # Read actual editable widget positions rather than assuming web
        # viewport coordinates; Android status bar and keyboard differ.
        editables = [n for n in nodes() if n.get("class") == "android.widget.EditText"]
        if len(editables) < 2:
            raise RuntimeError("Generator inputs not visible")
        for node, value in zip(editables[:2], ["10.10.14.8", "9001"]):
            x1, y1, x2, y2 = map(int, re.findall(r"\d+", node.get("bounds", "")))
            adb("shell", "input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2))
            adb("shell", "input", "text", value)
            adb("shell", "input", "keyevent", "4")
            time.sleep(0.7)
        tap_text("Generate One-Liner")
        cue("Payload dibuat dari input lab\nHasil otomatis masuk riwayat lokal", 3)
        adb("shell", "input", "swipe", "360", "1067", "360", "733", "400")
        cue("Hasil generator asli\nPoC tidak dieksekusi terhadap target", 4)
        screenshot("android-generator.png")
        tap_text("Riwayat aktivitas")
        cue("Riwayat persisten\nEntri berasal dari proses generate tadi")
        screenshot("android-history.png")
        tap_text("Reverse Shell")
        cue("Detail riwayat sebagai bottom sheet\nPayload dapat disalin")
        adb("shell", "input", "keyevent", "4")
        time.sleep(0.5)
        adb("shell", "input", "keyevent", "4")
        time.sleep(0.7)
        tap_text("Exploit")
        cue("Exploit Library lokal\nKatalog referensi untuk pengujian berizin")
        tap_text("CVE-2021-41773")
        cue("Detail layar penuh Android\nCVSS, referensi, dan cuplikan PoC", 5)
        screenshot("android-exploit.png")
        adb("shell", "input", "keyevent", "4")
        time.sleep(0.6)
        tap_text("Beranda")
        cue("Info Bot menggunakan DeepSeek\nPertanyaan dikirim langsung ke provider AI", 2)
        tap_design(975, 1900)
        time.sleep(1)
        tap_design(450, 1905)
        adb("shell", "input", "text", "Jelaskan%sLHOST%sdan%sLPORT%sdalam%sdua%skalimat.")
        adb("shell", "input", "keyevent", "4")
        time.sleep(1)
        tap_design(975, 1905)
        cue("Respons AI nyata dari DeepSeek\nWaktu tunggu jaringan tetap terlihat", 12)
        ai_nodes = nodes()
        ai_reply = any(
            "LHOST" in n.get("content-desc", "")
            and not n.get("content-desc", "").startswith("Jelaskan")
            and "Info Bot:" not in n.get("content-desc", "")
            for n in ai_nodes
        )
        if not ai_reply:
            raise RuntimeError("AI reply not verified; do not publish as a successful AI demo")
        screenshot("android-ai-response.png")
        cue("Jawaban tampil di aplikasi Android\nAPI key tidak ditampilkan atau disertakan dalam APK", 5)
        tap_design(975, 527)
        cue("PayloadHub-AI untuk lab dan target berizin\nDemo benar-benar berjalan di emulator Android", 5)
    finally:
        # SIGINT asks Android screenrecord to finalize the MP4 cleanly.
        adb("shell", "pkill", "-2", "screenrecord")
        recorder.wait(timeout=20)
    duration = time.monotonic() - started
    raw = OUT / "PayloadHub-AI-Android-Asli.mp4"
    adb("pull", "/sdcard/payloadhub-demo.mp4", str(raw))
    from record_demo import stamp

    srt = OUT / "PayloadHub-AI-Android.srt"
    srt.write_text("\n".join(
        f"{i + 1}\n{stamp(start)} --> {stamp(cues[i + 1][0] if i + 1 < len(cues) else duration)}\n{text}\n"
        for i, (start, text) in enumerate(cues)), encoding="utf-8")
    target = OUT / "PayloadHub-AI-Demo-Android.mp4"
    subprocess.run([
        imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-i", str(raw), "-vf",
        "scale=720:1560,pad=900:1800:90:40:color=0x0d1117,"
        "subtitles=PayloadHub-AI-Android.srt:force_style='FontName=Arial,FontSize=15,"
        "Outline=1,Alignment=2,MarginV=16'",
        "-c:v", "libx264", "-crf", "20", "-preset", "fast", "-pix_fmt", "yuv420p",
        "-movflags", "+faststart", "-an", str(target),
    ], cwd=OUT, check=True)
    (OUT / "android-recording.json").write_text(json.dumps({
        "source": "APK running in Android emulator; adb screenrecord",
        "emulator": SERIAL, "activity": ACTIVITY, "duration_seconds": duration,
        "video": target.name, "uncaptioned_original": raw.name,
        "backend_ai_shown": False, "direct_deepseek_chat_shown": True,
        "credentials_visible": False,
    }, indent=2), encoding="utf-8")
    print(f"Saved {target.name}, duration {duration:.1f}s")


if __name__ == "__main__":
    main()
