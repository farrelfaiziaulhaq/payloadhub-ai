#!/usr/bin/env python3
"""One-command developer helper for PayloadHub-AI.

Examples:
    python scripts/payloadhub.py setup
    python scripts/payloadhub.py backend
    python scripts/payloadhub.py desktop
    python scripts/payloadhub.py android
    python scripts/payloadhub.py apk
    python scripts/payloadhub.py doctor

The script only uses the Python standard library. It never writes API keys.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import NoReturn

ROOT = Path(__file__).resolve().parent.parent
BACKEND = ROOT / "backend"
FRONTEND = ROOT / "frontend"
IS_WINDOWS = os.name == "nt"
VENV_PYTHON = BACKEND / (".venv/Scripts/python.exe" if IS_WINDOWS else ".venv/bin/python")
ENV_FILE = BACKEND / ".env"
ENV_EXAMPLE = BACKEND / ".env.example"


def fail(message: str, code: int = 1) -> NoReturn:
    print(f"\n[ERROR] {message}\n", file=sys.stderr)
    raise SystemExit(code)


def run(
    args: list[str],
    *,
    cwd: Path = ROOT,
    env: dict[str, str] | None = None,
    capture: bool = False,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    args = [str(item) for item in args]
    if IS_WINDOWS and Path(args[0]).suffix.lower() in {".bat", ".cmd"}:
        args = ["cmd", "/c", *args]
    print("$ " + " ".join(args), flush=True)
    result = subprocess.run(
        args,
        cwd=str(cwd),
        env=env,
        text=True,
        capture_output=capture,
    )
    if check and result.returncode != 0:
        fail(f"Perintah gagal (exit {result.returncode}).", result.returncode)
    return result


def flutter_bin() -> str:
    found = shutil.which("flutter")
    if found is None:
        fail(
            "Flutter tidak ditemukan di PATH.\n"
            "Install Flutter stable, lalu buka terminal baru:\n"
            "  https://docs.flutter.dev/install\n"
            "Setelah itu jalankan: python scripts/payloadhub.py doctor",
            2,
        )
    return found


def venv_python() -> Path:
    if not VENV_PYTHON.exists():
        fail(
            "Virtual environment backend belum ada.\n"
            "Jalankan dulu: python scripts/payloadhub.py setup",
            2,
        )
    return VENV_PYTHON


def read_env() -> dict[str, str]:
    if not ENV_FILE.exists():
        return {}
    values: dict[str, str] = {}
    for line in ENV_FILE.read_text(encoding="utf-8-sig").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def ensure_env_file() -> None:
    if ENV_FILE.exists():
        return
    if not ENV_EXAMPLE.exists():
        fail("backend/.env.example tidak ditemukan di repository.")
    shutil.copy2(ENV_EXAMPLE, ENV_FILE)
    print(f"[OK] Membuat {ENV_FILE.relative_to(ROOT)} dari .env.example")
    print("     Isi LLM_API_KEY sebelum memakai fitur AI.")


def check_python() -> None:
    if sys.version_info < (3, 10):
        fail(f"Python 3.10+ dibutuhkan, versi saat ini {sys.version.split()[0]}.")
    print(f"[OK] Python {sys.version.split()[0]}")


def command_setup(args: argparse.Namespace) -> None:
    check_python()
    if not (BACKEND / "requirements.txt").exists():
        fail("backend/requirements.txt tidak ditemukan.")
    if not VENV_PYTHON.exists():
        print("[1/3] Membuat virtual environment backend...")
        run([sys.executable, "-m", "venv", str(BACKEND / ".venv")])
    else:
        print("[1/3] Virtual environment backend sudah ada.")
    print("[2/3] Memasang dependency backend...")
    run([str(VENV_PYTHON), "-m", "pip", "install", "--upgrade", "pip"])
    run([str(VENV_PYTHON), "-m", "pip", "install", "-r", str(BACKEND / "requirements.txt")])
    ensure_env_file()
    if args.skip_flutter:
        print("[3/3] Flutter dilewati (--skip-flutter).")
    else:
        print("[3/3] Mengambil dependency Flutter...")
        run([flutter_bin(), "pub", "get"], cwd=FRONTEND)
    print(
        "\n[OK] Setup selesai.\n"
        "Langkah berikutnya:\n"
        "  1. Isi backend/.env (LLM_API_KEY) bila memakai fitur AI.\n"
        "  2. Jalankan backend:  python scripts/payloadhub.py backend\n"
        "  3. Jalankan desktop: python scripts/payloadhub.py desktop\n"
        "     atau Android:    python scripts/payloadhub.py android\n"
        "  4. Cek kesehatan:  python scripts/payloadhub.py doctor\n"
    )


def command_backend(args: argparse.Namespace) -> None:
    env_python = venv_python()
    ensure_env_file()
    values = read_env()
    key = values.get("LLM_API_KEY", "").strip()
    if not key or key in {"sk-xxxxxxxxxxxxxxxx", "isi_api_key_anda"}:
        print(
            "[WARN] LLM_API_KEY belum diisi. Dashboard, generator offline, "
            "library, dan riwayat tetap jalan; fitur AI akan menampilkan error."
        )
    command = [
        str(env_python),
        "-m",
        "uvicorn",
        "app.main:app",
        "--host",
        args.host,
        "--port",
        str(args.port),
    ]
    if not args.no_reload:
        command.append("--reload")
    print(f"Backend: http://{args.host}:{args.port}  (health: /healthz)")
    print("Tekan Ctrl+C untuk berhenti.")
    run(command, cwd=BACKEND)


def desktop_device() -> str:
    if sys.platform.startswith("win"):
        return "windows"
    if sys.platform == "darwin":
        return "macos"
    return "linux"


def command_desktop(args: argparse.Namespace) -> None:
    device = args.device or desktop_device()
    command = [flutter_bin(), "run", "-d", device]
    if args.release:
        command.append("--release")
    print(f"Menjalankan Flutter desktop pada device: {device}")
    run(command, cwd=FRONTEND)


def command_web(args: argparse.Namespace) -> None:
    command = [flutter_bin(), "run", "-d", args.device]
    if args.release:
        command.append("--release")
    run(command, cwd=FRONTEND)


def list_flutter_devices() -> list[str]:
    result = run([flutter_bin(), "devices"], cwd=FRONTEND, capture=True, check=False)
    devices: list[str] = []
    for line in (result.stdout or "").splitlines():
        if "android" not in line.lower() or "•" not in line:
            continue
        device = line.split("•", 1)[0].strip()
        if device:
            devices.append(device)
    return devices


def command_android(args: argparse.Namespace) -> None:
    device = args.device
    if not device:
        devices = list_flutter_devices()
        if not devices:
            fail(
                "Tidak ada perangkat Android yang terdeteksi.\n"
                "Nyalakan emulator Android Studio, atau hubungkan HP dengan USB debugging,\n"
                "lalu cek: flutter devices\n"
                "Untuk memasang APK jadi tanpa build: lihat README bagian 'Android (APK)'.",
                2,
            )
        device = devices[0]
        print(f"[OK] Memakai perangkat Android: {device}")
    command = [flutter_bin(), "run", "-d", device]
    if args.release:
        command.append("--release")
    run(command, cwd=FRONTEND)


def android_env() -> dict[str, str]:
    env = os.environ.copy()
    if IS_WINDOWS and not env.get("JAVA_HOME"):
        candidates = [
            Path(r"C:\Program Files\Java\jdk-20"),
            Path(r"C:\Program Files\Java\jdk-17"),
        ]
        for candidate in candidates:
            if candidate.exists():
                env["JAVA_HOME"] = str(candidate)
                print(f"[OK] JAVA_HOME untuk build: {candidate}")
                break
    return env


def command_apk(args: argparse.Namespace) -> None:
    command = [flutter_bin(), "build", "apk", "--release"]
    if args.split_per_abi:
        command.append("--split-per-abi")
    print("Membangun APK rilis. Proses pertama bisa beberapa menit.")
    run(command, cwd=FRONTEND, env=android_env())
    apk_dir = FRONTEND / "build" / "app" / "outputs" / "flutter-apk"
    apks = sorted(apk_dir.glob("*.apk"))
    if not apks:
        fail(f"Build selesai tetapi APK tidak ditemukan di {apk_dir}.")
    print("\n[OK] APK siap:")
    for apk in apks:
        print(f"  {apk}  ({apk.stat().st_size / (1024 * 1024):.1f} MB)")


def command_doctor(_: argparse.Namespace) -> None:
    check_python()
    print(f"[INFO] Root: {ROOT}")
    print(f"[INFO] Backend venv: {'ada' if VENV_PYTHON.exists() else 'BELUM ADA'}")
    print(f"[INFO] backend/.env: {'ada' if ENV_FILE.exists() else 'BELUM ADA'}")
    found_flutter = shutil.which("flutter")
    if found_flutter:
        print(f"[OK] Flutter: {found_flutter}")
        run([found_flutter, "--version"], cwd=ROOT, check=False)
    else:
        print("[MISSING] Flutter tidak ada di PATH")
    print("\n[flutter doctor]")
    if found_flutter:
        run([found_flutter, "doctor", "-v"], cwd=ROOT, check=False)
    else:
        print("Install Flutter: https://docs.flutter.dev/install")
    print(
        "\nPanduan lengkap: README.md dan docs/INSTALASI.md\n"
        "Android SDK/emulator: https://developer.android.com/studio\n"
        "Visual Studio (Windows desktop): https://visualstudio.microsoft.com/downloads/"
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Setup dan jalankan PayloadHub-AI dengan mudah.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = parser.add_subparsers(dest="command", required=True)

    setup_parser = sub.add_parser("setup", help="Pasang dependency backend + Flutter")
    setup_parser.add_argument("--skip-flutter", action="store_true")
    setup_parser.set_defaults(func=command_setup)

    backend_parser = sub.add_parser("backend", help="Jalankan FastAPI")
    backend_parser.add_argument("--host", default="0.0.0.0")
    backend_parser.add_argument("--port", type=int, default=8000)
    backend_parser.add_argument("--no-reload", action="store_true")
    backend_parser.set_defaults(func=command_backend)

    desktop_parser = sub.add_parser("desktop", help="Jalankan aplikasi desktop")
    desktop_parser.add_argument("--device")
    desktop_parser.add_argument("--release", action="store_true")
    desktop_parser.set_defaults(func=command_desktop)

    web_parser = sub.add_parser("web", help="Jalankan aplikasi di Chrome")
    web_parser.add_argument("--device", default="chrome")
    web_parser.add_argument("--release", action="store_true")
    web_parser.set_defaults(func=command_web)

    android_parser = sub.add_parser("android", help="Jalankan aplikasi di Android")
    android_parser.add_argument("--device")
    android_parser.add_argument("--release", action="store_true")
    android_parser.set_defaults(func=command_android)

    apk_parser = sub.add_parser("apk", help="Build APK rilis")
    apk_parser.add_argument("--split-per-abi", action="store_true")
    apk_parser.set_defaults(func=command_apk)

    doctor_parser = sub.add_parser("doctor", help="Cek tool yang sudah terpasang")
    doctor_parser.set_defaults(func=command_doctor)
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
