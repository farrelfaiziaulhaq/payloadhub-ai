# PayloadHub-AI

Aplikasi **ethical hacking assistant** untuk pengujian keamanan yang memiliki
otorisasi. Klien Flutter berjalan di **Android dan desktop**; backend FastAPI
menyediakan agent AI, katalog ExploitDB, dan threat intelligence.

> Gunakan hanya pada sistem milik sendiri, lab, CTF, atau target dengan izin
> tertulis. Jangan menjalankan payload ke target tanpa otorisasi.

## Pilih cara menjalankan

| Saya ingin... | Jalur | Waktu |
|---|---|---|
| Langsung mencoba di HP | **APK jadi** — tidak perlu build | ±2 menit |
| Demo di laptop Windows | **Desktop** + backend | ±10 menit |
| Ngoding Android | **Android dari source** | ±15 menit |
| Demo di Linux/macOS | **Desktop** + backend | ±10 menit |

Panduan langkah demi langkah dari komputer kosong ada di
**[`docs/INSTALASI.md`](docs/INSTALASI.md)**.

---

## Quick start (setelah Flutter & Python terpasang)

Dari root repository:

```bash
python scripts/payloadhub.py setup
```

Lalu buka **dua terminal**:

```bash
# Terminal 1 — backend
python scripts/payloadhub.py backend

# Terminal 2 — aplikasi desktop
python scripts/payloadhub.py desktop
```

Android:

```bash
python scripts/payloadhub.py android
```

Cek semua tool:

```bash
python scripts/payloadhub.py doctor
```

Windows PowerShell bisa memakai `.\setup.ps1`; Linux/macOS memakai
`./setup.sh`.

---

## 1. Prasyarat

| Tool | Versi yang diuji | Wajib untuk |
|---|---|---|
| Python | 3.10+ | Backend |
| Flutter | 3.47.2 stable | Aplikasi |
| JDK | **20** | Build Android |
| Android Studio + SDK | 36 / Build-Tools 35 | Android |
| Visual Studio 2022 | Desktop development with C++ | Desktop Windows |
| Xcode + CocoaPods | terbaru | Desktop/iOS macOS |

- Install Flutter: <https://docs.flutter.dev/install>
- Install Android Studio: <https://developer.android.com/studio>
- Install Python: <https://www.python.org/downloads/>
- Install JDK 20: <https://adoptium.net/temurin/releases/?version=20>

Setelah instalasi, buka terminal baru:

```bash
flutter doctor -v
flutter doctor --android-licenses
```

Android SDK Manager perlu: **Platform 36**, **Build-Tools 35.0.0**,
**Command-line Tools**, dan **NDK 28.2.13676358**. Tanpa NDK, build APK
akan berhenti pada tahap lisensi.

Arahkan Flutter ke JDK 20 (Windows example):

```powershell
flutter config --jdk-dir="C:\Program Files\Java\jdk-20"
```

> JDK 25 dapat membuat build Android gagal. Gunakan JDK 20.

Prasyarat desktop:

- **Windows:** Visual Studio 2022 → workload **Desktop development with C++**.
- **Linux (Ubuntu/Debian):**

  ```bash
  sudo apt update
  sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev
  ```

- **macOS:** `xcode-select --install`, `sudo xcodebuild -license accept`,
  `sudo gem install cocoapods`.

---

## 2. Setup project

```bash
git clone https://github.com/farrelfaiziaulhaq/payloadhub-ai.git
cd payloadhub-ai
```

Windows:

```powershell
.\setup.ps1
```

Jika PowerShell memblokir script:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

Linux/macOS:

```bash
chmod +x setup.sh
./setup.sh
```

Atau langsung:

```bash
python scripts/payloadhub.py setup
```

Script membuat `backend/.venv`, memasang dependency, menyalin
`backend/.env.example` → `backend/.env` (jika belum ada), dan menjalankan
`flutter pub get`.

### Isi `backend/.env`

```dotenv
LLM_API_KEY=isi_key_provider_anda
LLM_BASE_URL=https://api.deepseek.com
LLM_MODEL=deepseek-chat
VIRUSTOTAL_API_KEY=
```

`LLM_API_KEY` hanya diperlukan untuk fitur AI. Tanpa key:

- dashboard, generator, exploit library, riwayat, dan Settings tetap jalan;
- Info Bot/agent menampilkan pesan error yang jelas.

Jangan commit `.env`. File tersebut sudah masuk `.gitignore`.

---

## 3. Android (APK jadi, paling cepat)

1. Download APK dari
   [Releases v1.0.0](https://github.com/farrelfaiziaulhaq/payloadhub-ai/releases/tag/v1.0.0).
2. Pindahkan ke HP.
3. Buka APK → izinkan **Install unknown apps** → **Install**.
4. Buka **PayloadHub-AI**.

| Atribut | Nilai |
|---|---|
| Application ID | `id.farrel.payloadhubai` |
| Minimum Android | 5.0 (API 21) |
| Ukuran | ±55,5 MB |
| Signature | debug key (demo/lab) |

Fitur offline langsung tersedia. Untuk AI di HP fisik, lihat
[Koneksi backend](#7-koneksi-backend).

---

## 4. Android dari source

```bash
python scripts/payloadhub.py setup
flutter devices
python scripts/payloadhub.py android
```

Pilih perangkat tertentu:

```bash
python scripts/payloadhub.py android --device emulator-5554
```

Build APK:

```bash
python scripts/payloadhub.py apk
```

Output:

```text
frontend/build/app/outputs/flutter-apk/app-release.apk
```

Pasang manual:

```bash
adb install -r frontend/build/app/outputs/flutter-apk/app-release.apk
```

---

## 5. Desktop

Windows:

```powershell
flutter config --enable-windows-desktop
python scripts/payloadhub.py desktop
```

Linux:

```bash
flutter config --enable-linux-desktop
python scripts/payloadhub.py desktop
```

macOS:

```bash
flutter config --enable-macos-desktop
python scripts/payloadhub.py desktop
```

Atau manual:

```bash
cd frontend
flutter run -d windows     # atau linux / macos
```

Build rilis:

```bash
cd frontend
flutter build windows      # atau linux / macos
```

---

## 6. Backend

```bash
python scripts/payloadhub.py backend
```

Manual:

```bash
# Windows
backend\.venv\Scripts\Activate.ps1
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Linux/macOS
source backend/.venv/bin/activate
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Verifikasi:

```bash
curl http://127.0.0.1:8000/healthz
# {"status":"ok"}
```

Dokumentasi API: <http://127.0.0.1:8000/docs>

---

## 7. Koneksi backend

| Target | Default | Kapan diubah |
|---|---|---|
| Desktop / web | `http://localhost:8000` | Jika backend di komputer lain |
| Emulator Android | `http://10.0.2.2:8000` | Tidak perlu diubah |
| HP Android fisik | `http://IP-LAN:8000` | **Wajib** diatur |

Untuk HP fisik:

1. HP dan komputer di Wi-Fi yang sama.
2. Backend berjalan dengan `--host 0.0.0.0`.
3. Izinkan port 8000 di firewall.
4. Aplikasi → **Settings → Backend Server**.
5. Isi `http://192.168.1.10:8000` (sesuaikan IP komputer).
6. Simpan → tutup dan buka ulang aplikasi.
7. Uji dari browser HP: `http://192.168.1.10:8000/healthz`.

Tidak perlu edit kode. Untuk produksi gunakan HTTPS dan batasi
`CORS_ALLOW_ORIGINS`.

---

## 8. Verifikasi

```bash
python scripts/payloadhub.py doctor
cd frontend
flutter analyze
flutter test
```

Checklist:

- [ ] Aplikasi terbuka.
- [ ] Bottom navigation (HP) / sidebar (desktop) berfungsi.
- [ ] Generator menghasilkan payload `10.10.14.8:9001`.
- [ ] Payload masuk **Riwayat Aktivitas**.
- [ ] Settings menyimpan LHOST/LPORT dan URL backend.
- [ ] Backend `/healthz` mengembalikan `{"status":"ok"}`.
- [ ] Jika memakai AI, Info Bot menjawab.

---

## 9. Troubleshooting singkat

| Masalah | Solusi |
|---|---|
| `flutter` tidak dikenali | Tambah `flutter/bin` ke PATH, buka terminal baru |
| `No devices found` | Nyalakan emulator / aktifkan USB debugging |
| Build APK gagal | Pakai JDK 20, jalankan `flutter doctor -v` |
| Visual Studio tidak ditemukan | Install workload C++ |
| HP tidak connect ke backend | Pakai IP LAN, bukan `localhost`; cek firewall |
| Emulator tidak connect | Gunakan `10.0.2.2:8000` |
| AI 401/403 | Isi `LLM_API_KEY`, restart backend |
| APK tidak bisa install | Izinkan install dari sumber tidak dikenal |

Panduan lengkap: [`docs/INSTALASI.md`](docs/INSTALASI.md).

---

## Fitur

- Dashboard mobile-first: header aplikasi, kartu sambutan, alat cepat,
  bottom navigation, dan FAB bantuan.
- Layout desktop tiga kolom + sidebar.
- Script Generator deterministik dan tervalidasi.
- Exploit Library lokal + pencarian ExploitDB.
- Agent AI dengan guardrail dan deterministic tool calling.
- Threat Intelligence VirusTotal.
- Riwayat aktivitas lokal terenkripsi (maks. 40 entri).
- Settings aman: API key di secure storage, URL backend bisa diubah dari UI.

## Struktur project

```text
payloadhub-ai/
├── backend/
│   ├── app/                 # FastAPI, agent, tools, model
│   ├── requirements.txt
│   └── .env.example
├── frontend/
│   ├── lib/                 # Flutter
│   ├── test/                # unit + widget tests
│   └── pubspec.yaml
├── scripts/
│   └── payloadhub.py        # setup/run/build helper
├── docs/                    # laporan, instalasi, screenshot, demo
├── setup.ps1 / setup.sh
└── README.md
```

## Dokumentasi

| Dokumen | Isi |
|---|---|
| [`docs/INSTALASI.md`](docs/INSTALASI.md) | Instalasi lengkap Android/desktop/backend || [`docs/DOKUMENTASI-TEKNIS.md`](docs/DOKUMENTASI-TEKNIS.md) | Arsitektur, API, storage, build |
| [`docs/Tahap-1-Analisis-Kebutuhan.md`](docs/Tahap-1-Analisis-Kebutuhan.md) | Analisis kebutuhan |
| [`docs/Tahap-2-Perancangan-Sistem.md`](docs/Tahap-2-Perancangan-Sistem.md) | Perancangan & UI |
| [`docs/Tahap-3-Implementasi.md`](docs/Tahap-3-Implementasi.md) | Implementasi |
| [`docs/Tahap-4-Pengujian.md`](docs/Tahap-4-Pengujian.md) | Pengujian |
| [`docs/Tahap-5-Laporan-Akhir.md`](docs/Tahap-5-Laporan-Akhir.md) | Laporan akhir |
| [`docs/PayloadHub-AI-Laporan-Lengkap.md`](docs/PayloadHub-AI-Laporan-Lengkap.md) | Laporan gabungan |
| [`docs/demo/PayloadHub-AI-Demo-Android.mp4`](docs/demo/PayloadHub-AI-Demo-Android.mp4) | Video demo Android |
| [`docs/docx/`](docs/docx) | Versi Word |

## Lisensi

Belum ada file lisensi. Tambahkan lisensi yang sesuai sebelum distribusi
publik atau komersial.
