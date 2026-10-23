# PayloadHub-AI

PayloadHub-AI adalah aplikasi **ethical hacking assistant** untuk membantu
pengujian keamanan yang memiliki otorisasi. Project ini terdiri dari:

- **Frontend:** aplikasi Flutter multiplatform (`frontend/`) dengan dashboard,
  Exploit Library, Script Generator, Monitoring, Threat Intelligence,
  Settings, dan Riwayat Aktivitas lokal.
- **Backend:** API FastAPI (`backend/`) yang menjalankan agent LangChain dan
  tool deterministik untuk membuat reverse-shell yang tervalidasi, membaca
  hasil Nmap/CVE, menganalisis JWT, mencari katalog ExploitDB, dan meneruskan
  permintaan VirusTotal.

> Gunakan hanya pada sistem milik sendiri, lab, CTF, atau target yang memiliki
> izin tertulis. Jangan menjalankan hasil aplikasi pada target tanpa otorisasi.

## Dokumentasi Proyek Akhir

| Tahap | Dokumen |
|---|---|
| 1 â€” Analisis kebutuhan | [`docs/Tahap-1-Analisis-Kebutuhan.md`](docs/Tahap-1-Analisis-Kebutuhan.md) |
| 2 â€” Perancangan sistem & UI | [`docs/Tahap-2-Perancangan-Sistem.md`](docs/Tahap-2-Perancangan-Sistem.md) |
| 3 â€” Implementasi Flutter | [`docs/Tahap-3-Implementasi.md`](docs/Tahap-3-Implementasi.md) |
| 4 â€” Integrasi & pengujian | [`docs/Tahap-4-Pengujian.md`](docs/Tahap-4-Pengujian.md) |
| 5 â€” Finalisasi & laporan | [`docs/Tahap-5-Laporan-Akhir.md`](docs/Tahap-5-Laporan-Akhir.md) |
| Wireframe & purwarupa | [`docs/assets/`](docs/assets), [`docs/prototipe/index.html`](docs/prototipe/index.html) |
| Panduan demo video | [`docs/PANDUAN-DEMO-VIDEO.md`](docs/PANDUAN-DEMO-VIDEO.md) |
| Bahan presentasi | [`docs/BAHAN-PRESENTASI.md`](docs/BAHAN-PRESENTASI.md) |
| Dokumentasi teknis | [`docs/DOKUMENTASI-TEKNIS.md`](docs/DOKUMENTASI-TEKNIS.md) |
| Versi Word semua laporan | [`docs/docx/`](docs/docx) |

## Fitur utama

- Dashboard responsif: kartu bertumpuk di ponsel, tiga kolom di layar lebar.
- Navigasi adaptif: *bottom navigation* di ponsel, *sidebar* di desktop.
- Generator one-liner dan payload deterministik dari library internal.
- Agent AI backend dengan validasi input dan guardrail anti-halusinasi.
- Exploit Library lokal serta pencarian katalog ExploitDB resmi.
- Threat intelligence VirusTotal untuk URL, file, hash, domain, dan IP.
- Riwayat aktivitas lokal terenkripsi (maks. 40 entri) dengan salin, hapus,
  dan ekspor JSON.
- Penyimpanan API key di secure storage Flutter; key LLM backend tetap berada
  di server.

## Struktur project

```text
payloadhub-ai/
â”œâ”€â”€ backend/
â”‚   â”œâ”€â”€ app/                 # FastAPI, agent, models, dan deterministic tools
â”‚   â”œâ”€â”€ requirements.txt
â”‚   â””â”€â”€ .env.example
â”œâ”€â”€ frontend/
â”‚   â”œâ”€â”€ lib/                 # Aplikasi Flutter/Dart
â”‚   â”œâ”€â”€ test/                # Unit + widget tests
â”‚   â””â”€â”€ pubspec.yaml
â”œâ”€â”€ docs/                    # Laporan Tahap 1â€“5, wireframe, purwarupa
â”œâ”€â”€ BLUEPRINT.md             # Spesifikasi teknis dan kontrak API
â””â”€â”€ README.md
```

## Prasyarat

### Wajib

- Git.
- **Flutter SDK stable** dengan Dart SDK yang memenuhi `>=3.3.0 <4.0.0`.
- Python 3.10 atau lebih baru untuk backend.
- Koneksi internet saat mengambil dependency dan saat memakai provider cloud.

Panduan resmi instalasi Flutter tersedia di
<https://docs.flutter.dev/install>. Setelah instalasi, pastikan perintah
`flutter` dan `dart` tersedia di `PATH`.

### Linux desktop (opsional, untuk `flutter run -d linux`)

Pada Ubuntu/Debian, install toolchain berikut sesuai panduan Flutter:

```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev
```

Referensi resmi: <https://docs.flutter.dev/platform-integration/linux/setup>.

### Android (opsional)

Install Android Studio stable, Android SDK, Android SDK Platform-Tools, dan
buat emulator atau hubungkan perangkat fisik dengan USB debugging aktif.
Kemudian jalankan:

```bash
flutter doctor --android-licenses
flutter doctor -v
```

Panduan resmi Android + Flutter:
<https://docs.flutter.dev/platform-integration/android/setup>.

## Instalasi dependency

### 1. Backend FastAPI

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate              # Linux/macOS
# Windows PowerShell: .venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
cp .env.example .env
```

Edit `backend/.env` dan isi minimal konfigurasi LLM. Contoh default project
menggunakan DeepSeek yang kompatibel dengan API OpenAI:

```dotenv
LLM_API_KEY=isi_api_key_anda
LLM_BASE_URL=https://api.deepseek.com
LLM_MODEL=deepseek-chat
LLM_TEMPERATURE=0.0
```

`LLM_API_KEY` wajib diisi bila memakai fitur agent AI. `VIRUSTOTAL_API_KEY`
bersifat opsional; key dapat dimasukkan dari menu Settings atau dikonfigurasi
di backend. Jangan commit `.env`, file `api-*`, atau key provider apa pun.

### 2. Frontend Flutter

Buka terminal baru atau keluar dari virtualenv, lalu jalankan:

```bash
cd frontend
flutter pub get
flutter doctor -v
```

Dependency utama frontend dideklarasikan di `frontend/pubspec.yaml`, antara
lain Flutter Riverpod, Dio, Flutter Secure Storage, File Picker, Google Fonts,
dan syntax highlighting.

## Menjalankan aplikasi

### Backend

Terminal 1:

```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Verifikasi backend dari terminal lain:

```bash
curl http://127.0.0.1:8000/healthz
```

Response yang benar adalah `{"status":"ok"}`.

### Frontend Linux desktop

Terminal 2:

```bash
cd frontend
flutter run -d linux
```

### Frontend Web

```bash
cd frontend
flutter run -d chrome
```

### Frontend Android

Pastikan emulator/perangkat terlihat dengan `flutter devices`, lalu:

```bash
cd frontend
flutter run -d <device-id>
```

Konfigurasi URL backend saat ini adalah:

| Target | URL default |
|---|---|
| Linux, Windows, macOS, Web | `http://localhost:8000` |
| Android Emulator | `http://10.0.2.2:8000` |
| Android fisik | IP LAN komputer, misalnya `http://192.168.1.10:8000` |

Untuk perangkat fisik, ubah `defaultBaseUrl` di
`frontend/lib/features/dashboard/presentation/dashboard_providers.dart`,
jalankan backend pada `0.0.0.0`, dan pastikan firewall mengizinkan port 8000.
Untuk deployment nyata gunakan HTTPS dan batasi `CORS_ALLOW_ORIGINS`.

## Pengujian dan build

```bash
# Frontend
cd frontend
flutter pub get
flutter analyze
flutter test
flutter build apk --release       # Android
flutter build web                 # Web
flutter build linux               # Linux desktop
```

Hasil verifikasi terakhir (23 Oktober 2026):

```text
flutter analyze   â†’ No issues found!
flutter test      â†’ 00:06 +16: All tests passed!
flutter build apk â†’ app-release.apk (55,2 MB)
```

### Build APK Android

Persyaratan toolchain yang sudah diuji:

| Komponen | Versi |
|---|---|
| Flutter | 3.47.2 stable |
| JDK | OpenJDK **20** (JDK 25 tidak kompatibel dengan Gradle 8.14) |
| Gradle | 8.14.3 |
| Android Gradle Plugin | 8.11.1 |
| Kotlin | 2.2.20 |
| Android SDK | 36, Build-Tools 35.0.0 |

```bash
flutter config --jdk-dir="/path/to/jdk-20"
cd frontend
flutter build apk --release
```

Keluaran: `frontend/build/app/outputs/flutter-apk/app-release.apk`
(applicationId `id.farrel.payloadhubai`, minSdk 21, SHA-256
`7F71676147E77EA323B26D172C99F7BA30C3CF7C0B6252E06263EFDAB15B1479`).

APK yang sudah dibangun tersedia sebagai aset rilis:
<https://github.com/farrelfaiziaulhaq/payloadhub-ai/releases/tag/v1.0.0>.

APK saat ini ditandatangani debug key. Untuk distribusi publik, buat keystore
rilis dan jangan commit `key.properties` atau berkas `.jks`.

Pengecekan backend dasar:

```bash
cd backend
source .venv/bin/activate
python -m compileall -q app
python -c "from app.main import app; print(app.title)"
```

## Konfigurasi environment

Semua konfigurasi backend dibaca dari `backend/.env`:

| Variable | Wajib | Keterangan |
|---|---:|---|
| `LLM_API_KEY` | Ya untuk agent | Key provider LLM di server |
| `LLM_BASE_URL` | Tidak | Base URL OpenAI-compatible |
| `LLM_MODEL` | Tidak | Default model yang digunakan agent |
| `LLM_TEMPERATURE` | Tidak | Default `0.0` untuk hasil konsisten |
| `AGENT_MAX_ITERATIONS` | Tidak | Batas iterasi tool agent |
| `AGENT_TIMEOUT_SECONDS` | Tidak | Batas waktu agent |
| `VIRUSTOTAL_API_KEY` | Tidak | Mengaktifkan lookup/scan VirusTotal |
| `VIRUSTOTAL_MAX_FILE_BYTES` | Tidak | Batas ukuran upload |
| `EXPLOITDB_CSV_URL` | Tidak | Sumber katalog ExploitDB |
| `CORS_ALLOW_ORIGINS` | Tidak | Origin frontend yang diizinkan |

Frontend menyimpan key yang diisi pengguna memakai `flutter_secure_storage`.
Tidak ada credential yang dibundel ke aplikasi. Upload file ke VirusTotal
Community API bersifat publik; jangan upload file rahasia.

## Endpoint backend

- `GET /healthz` â€” health check.
- `POST /api/v1/agent/execute` â€” menjalankan agent dengan prompt dan context.
- `GET /api/v1/exploitdb/search?q=...` â€” mencari katalog ExploitDB.
- `/api/v1/virustotal/*` â€” status, scan, analysis, dan lookup indikator.

Dokumentasi OpenAPI tersedia saat backend berjalan di
<http://127.0.0.1:8000/docs>.

## Troubleshooting

### `flutter: command not found`

Tambahkan folder `flutter/bin` ke `PATH`, buka terminal baru, lalu jalankan
`flutter doctor -v`.

### Frontend tidak terhubung ke backend

Pastikan Uvicorn aktif di port 8000, cek `/healthz`, dan gunakan URL sesuai
target pada tabel di atas. Android Emulator tidak memakai `localhost` untuk
mengakses host komputer; gunakan `10.0.2.2`.

### Agent mengembalikan error provider

Periksa `LLM_API_KEY`, `LLM_BASE_URL`, `LLM_MODEL`, koneksi internet, dan log
terminal Uvicorn. VirusTotal juga membutuhkan key terpisah untuk fitur
Threat Intelligence.

### `flutter doctor` memberi warning platform

Warning platform yang tidak ditargetkan dapat diabaikan. Selesaikan hanya
toolchain target yang ingin digunakan, misalnya Linux desktop atau Android.

## Lisensi

Belum ada file lisensi di repository ini. Tambahkan lisensi yang sesuai
sebelum distribusi publik atau penggunaan komersial.
