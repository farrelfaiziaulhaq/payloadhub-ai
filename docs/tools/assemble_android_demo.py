"""Assemble verified, real adb recordings; trim only idle gaps between steps."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess

import imageio_ffmpeg

from record_demo import stamp


def main() -> None:
    out = Path(__file__).resolve().parents[1] / "demo"
    first = out / "android-part1.mp4"
    second = out / "android-part2.mp4"
    for path in (first, second):
        if not path.exists():
            raise FileNotFoundError(path)
    # Reviewed against a timestamped contact sheet. Keep actual generation,
    # keyboard input, loading indicator and DeepSeek response at real speed.
    segments = [(0, 0, 33), (1, 18, 33), (1, 46, 61), (1, 101, 142)]
    captions = [
        (0, 5, "PayloadHub-AI | APK asli di emulator Android\nRekaman layar langsung, bukan mockup"),
        (5, 33, "Generator mobile\nInput lab, payload deterministik, dan hasil asli"),
        (33, 48, "Riwayat aktivitas dan detail\nEntri dibuat dari proses generate sebelumnya"),
        (48, 63, "Exploit Library dan detail layar penuh\nReferensi bawaan; PoC tidak dieksekusi"),
        (63, 96, "Info Bot dengan DeepSeek\nPertanyaan dan respons langsung di Android"),
        (96, 104, "Jawaban DeepSeek tampil di aplikasi\nGunakan hanya untuk lab dan target berizin"),
    ]
    subtitle = out / "PayloadHub-AI-Android.srt"
    subtitle.write_text("\n".join(
        f"{i + 1}\n{stamp(start)} --> {stamp(end)}\n{text}\n"
        for i, (start, end, text) in enumerate(captions)), encoding="utf-8")
    def ass_time(seconds: float) -> str:
        return str(int(seconds // 3600)) + stamp(seconds)[2:].replace(",", ".")[:-1]

    ass = out / "PayloadHub-AI-Android.ass"
    ass.write_text(
        "[Script Info]\nScriptType: v4.00+\nPlayResX: 900\nPlayResY: 1800\n"
        "WrapStyle: 0\n[V4+ Styles]\n"
        "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\n"
        "Style: Default,Arial,28,&H00FFFFFF,&H00FFFFFF,&H0017110D,&H0017110D,0,0,0,0,100,100,0,0,1,1,0,2,35,35,75,1\n"
        "[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n"
        + "\n".join(
            f"Dialogue: 0,{ass_time(start)},{ass_time(end)},Default,,0,0,0,,"
            + text.replace("\n", "\\N") for start, end, text in captions
        ), encoding="utf-8",
    )
    filters = []
    for index, (source, start, end) in enumerate(segments):
        filters.append(
            f"[{source}:v]trim=start={start}:end={end},setpts=PTS-STARTPTS,"
            f"fps=25,setsar=1[s{index}]"
        )
    filters.append(
        "[s0][s1][s2][s3]concat=n=4:v=1:a=0,"
        "pad=900:1800:90:40:color=0x0d1117,"
        "subtitles=PayloadHub-AI-Android.ass[v]"
    )
    target = out / "PayloadHub-AI-Demo-Android.mp4"
    subprocess.run([
        imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-i", str(first), "-i", str(second),
        "-filter_complex", ";".join(filters), "-map", "[v]", "-c:v", "libx264",
        "-preset", "fast", "-crf", "20", "-pix_fmt", "yuv420p", "-an",
        "-movflags", "+faststart", str(target),
    ], cwd=out, check=True)
    (out / "android-recording.json").write_text(json.dumps({
        "source": "Real Android APK in Pixel 5 API 30 x64 emulator",
        "capture": "adb screenrecord", "output": target.name,
        "resolution": [900, 1800], "fps": 25,
        "expected_duration_seconds": 104,
        "editing": "Two real recordings joined; idle gaps trimmed; no speed changes",
        "source_segments": [
            {"file": [first.name, second.name][src], "start": start, "end": end}
            for src, start, end in segments
        ],
        "direct_deepseek_chat_shown": True,
        "backend_dynamic_generator_shown": False,
        "shodan_or_virustotal_shown": False,
        "audio": "No narration; Indonesian captions",
        "credentials_recorded": False,
    }, indent=2), encoding="utf-8")
    print(f"Created {target}")


if __name__ == "__main__":
    main()
