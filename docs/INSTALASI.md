# Panduan Instalasi PayloadHub-AI

Panduan ini dimulai dari komputer kosong sampai aplikasi berjalan di
**Android** atau **desktop**. Pilih salah satu jalur; tidak perlu mengerjakan
semua.

| Jalur | Paling mudah untuk | Perlu build? |
|---|---|---|
| **A. APK Android** | Pengguna biasa, presentasi | Tidak |
| **B. Android dari source** | Pengembangan mobile | Ya |
| **C. Desktop Windows** | Demo cepat di laptop | Ya |
| **D. Desktop Linux/macOS** | Pengembangan lintas platform | Ya |
| **E. Web** | Inspeksi cepat di browser | Ya |

Semua fitur offline (dashboard, generator, library, riwayat, Settings) tetap
jalan tanpa backend. Backend diperlukan untuk fitur AI, ExploitDB online, dan
VirusTotal.

---

## 0. Ambil Source Code

Install [Git](https://git-scm.com/downloads), lalu:

```bash
git clone https://github.com/farrelfaiziaulhaq/payloadhub-ai.git
cd payloadhub-ai
```

Belum punya Git? Download ZIP repository, ekstrak, lalu buka terminal di folder
tersebut.

---

## 1. Prasyarat Minimum

| Tool | Versi | Dipakai untuk |
|---|---|---|
| Python | 3.10+ | Backend FastAPI |
| Flutter | 3.47.2 stable (diuji) | Aplikasi klien |
| Git | terbaru | Clone dan update |
| Android Studio | terbaru | Android SDK/emulator |
| JDK | **20** | Build Android proyek ini |
| Visual Studio 2022 | Desktop development with C++ | Desktop Windows |
| Xcode | terbaru | Desktop/iOS macOS |

> JDK 25 dapat menyebabkan Gradle gagal. Proyek ini memakai Gradle 8.14.3,
> AGP 8.11.1, dan Kotlin 2.2.20; gunakan **JDK 20**.

### 1.1 Install Python

- Windows: <https://www.python.org/downloads/> — centang **Add Python to PATH**.
- macOS: `brew install python` atau installer python.org.
- Linux: `sudo apt install python3 python3-venv python3-pip`.

Cek:

```bash
python --version      # Windows
python3 --version     # Linux/macOS
```

### 1.2 Install Flutter

Ikuti panduan resmi sesuai OS:

- Windows: <https://docs.flutter.dev/get-started/install/windows>
- macOS: <https://docs.flutter.dev/get-started/install/macos>
- Linux: <https://docs.flutter.dev/get-started/install/linux>

Contoh Windows:

1. Download Flutter stable ZIP.
2. Ekstrak ke `C:\src\flutter` (jangan ke `C:\Program Files`).
3. Tambahkan `C:\src\flutter\bin` ke **PATH**.
4. Buka PowerShell baru, lalu:

```powershell
flutter --version
flutter doctor -v
```

Contoh Linux/macOS:

```bash
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$PATH:$HOME/flutter/bin"
flutter --version
flutter doctor -v
```

Tambahkan baris `export PATH=...` ke `~/.bashrc` atau `~/.zshrc` agar permanen.

### 1.3 Install Android Studio + SDK

1. Install [Android Studio](https://developer.android.com/studio).
2. Buka **SDK Manager** dan pasang:
   - Android SDK Platform 36
   - Android SDK Build-Tools 35.0.0
   - Android SDK Platform-Tools
   - Android SDK Command-line Tools (latest)
   - **NDK (Side by side) 28.2.13676358**
   - Android Emulator (opsional)
3. Setujui lisensi:

```bash
flutter doctor --android-licenses
```

Jika build berhenti karena NDK/lisensi, jalankan dari **SDK Manager** atau:

```bash
sdkmanager --licenses
sdkmanager "platforms;android-36" "build-tools;35.0.0" "ndk;28.2.13676358"
```

4. Buat emulator di **Device Manager** (misalnya Pixel 5 API 30) atau
   hubungkan HP dengan **USB debugging** aktif.

### 1.4 Install JDK 20

- Windows/macOS/Linux: install **Eclipse Temurin JDK 20** dari
  <https://adoptium.net/temurin/releases/?version=20>.
- Arahkan Flutter ke JDK tersebut:

```powershell
flutter config --jdk-dir="C:\Program Files\Java\jdk-20"
flutter doctor -v
```

Linux/macOS:

```bash
flutter config --jdk-dir="$HOME/.jdks/temurin-20"
```

### 1.5 Desktop Windows

Install [Visual Studio 2022](https://visualstudio.microsoft.com/downloads/)
dengan workload **Desktop development with C++** dan Windows 10/11 SDK.
Tanpa ini, `flutter run -d windows` akan gagal.

### 1.6 Desktop Linux

Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev
```

### 1.7 Desktop macOS

```bash
xcode-select --install
sudo xcodebuild -license accept
sudo gem install cocoapods
```

---

## 2. Setup Otomatis (Sekali Jalan)

Dari root repository:

**Windows PowerShell**

```powershell
.\setup.ps1
```

Jika muncul pesan *running scripts is disabled*, jalankan:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

**Linux/macOS**

```bash
chmod +x setup.sh
./setup.sh
```

Atau tanpa wrapper:

```bash
python scripts/payloadhub.py setup
```

Script akan:

1. membuat `backend/.venv`,
2. memasang dependency Python,
3. menyalin `backend/.env.example` menjadi `backend/.env` bila belum ada,
4. menjalankan `flutter pub get`.

Script **tidak** menulis API key dan tidak menimpa `.env` yang sudah ada.

Jika hanya ingin backend dulu:

```bash
python scripts/payloadhub.py setup --skip-flutter
```

### 2.1 Isi `backend/.env` (opsional untuk AI)

Buka `backend/.env` dengan editor:

```dotenv
LLM_API_KEY=isi_key_provider_anda
LLM_BASE_URL=https://api.deepseek.com
LLM_MODEL=deepseek-chat
VIRUSTOTAL_API_KEY=
```

- Tanpa `LLM_API_KEY`: aplikasi tetap jalan, fitur AI menampilkan pesan error.
- `VIRUSTOTAL_API_KEY` opsional untuk Threat Intelligence.
- Jangan commit `.env`; file ini sudah diabaikan Git.

---

## 3. Jalur A — Android Memakai APK Jadi (Paling Cepat)

1. Buka halaman rilis:
   <https://github.com/farrelfaiziaulhaq/payloadhub-ai/releases/tag/v1.0.0>
2. Download `PayloadHub-AI-v1.0.0.apk`.
3. Pindahkan ke HP (USB, Google Drive, atau download langsung).
4. Di HP, buka file APK → izinkan **Install unknown apps** untuk aplikasi
   pengelola file/browser → **Install**.
5. Buka **PayloadHub-AI**.

Spesifikasi APK:

| Atribut | Nilai |
|---|---|
| Application ID | `id.farrel.payloadhubai` |
| Minimum Android | 5.0 (API 21) |
| Ukuran | ±55,5 MB |
| Signature | debug key (untuk demo/lab) |

Fitur offline langsung tersedia. Untuk AI/Threat Intelligence, lanjutkan ke
Bagian 5 (backend) dan atur URL dari **Settings → Backend Server**.

---

## 4. Jalur B — Android dari Source

Prasyarat: Flutter, Android Studio/SDK, JDK 20, dan HP/emulator siap.

```bash
# 1. Backend dependency + Flutter dependency
python scripts/payloadhub.py setup

# 2. Cek perangkat
flutter devices

# 3. Jalankan aplikasi
python scripts/payloadhub.py android
```

Jika ada beberapa perangkat:

```bash
python scripts/payloadhub.py android --device emulator-5554
```

Build APK rilis:

```bash
python scripts/payloadhub.py apk
```

Hasil:

```text
frontend/build/app/outputs/flutter-apk/app-release.apk
```

Build pertama bisa 2–5 menit. Jika Gradle error soal Java:

```powershell
flutter config --jdk-dir="C:\Program Files\Java\jdk-20"
```

Pasang APK manual:

```bash
adb install -r frontend/build/app/outputs/flutter-apk/app-release.apk
```

---

## 5. Backend FastAPI

Terminal terpisah dari aplikasi:

```bash
python scripts/payloadhub.py backend
```

Atau manual:

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

Cek:

```bash
curl http://127.0.0.1:8000/healthz
# {"status":"ok"}
```

Dokumentasi API: <http://127.0.0.1:8000/docs>

### 5.1 URL backend dari aplikasi

| Target | Default | Catatan |
|---|---|---|
| Desktop / web | `http://localhost:8000` | Backend di komputer yang sama |
| Emulator Android | `http://10.0.2.2:8000` | `10.0.2.2` = localhost komputer host |
| HP Android fisik | URL LAN, mis. `http://192.168.1.10:8000` | Atur di Settings |

Untuk HP fisik:

1. Pastikan HP dan komputer berada di Wi-Fi yang sama.
2. Jalankan backend dengan `--host 0.0.0.0` (sudah default script).
3. Izinkan port 8000 di firewall.
4. Buka aplikasi → **Settings → Backend Server**.
5. Isi `http://IP-LAN-KOMPUTER:8000`, mis. `http://192.168.1.10:8000`.
6. Simpan, lalu **tutup dan buka ulang aplikasi**.
7. Uji dari HP: buka `http://IP-LAN:8000/healthz` di browser HP.

Tidak perlu mengedit kode untuk mengganti URL.

> `http://` hanya untuk lab lokal. Untuk produksi gunakan HTTPS dan batasi
> `CORS_ALLOW_ORIGINS`.

---

## 6. Jalur C — Desktop Windows

Prasyarat: Flutter dan Visual Studio C++ sudah terpasang.

```powershell
flutter config --enable-windows-desktop
flutter doctor -v
python scripts/payloadhub.py desktop
```

Atau:

```powershell
cd frontend
flutter run -d windows
```

Backend di terminal lain:

```powershell
python scripts/payloadhub.py backend
```

Build rilis:

```powershell
cd frontend
flutter build windows
```

Hasil ada di `frontend/build/windows/x64/runner/Release/`.

---

## 7. Jalur D — Desktop Linux

```bash
flutter config --enable-linux-desktop
flutter doctor -v
python scripts/payloadhub.py desktop
```

Atau:

```bash
cd frontend
flutter run -d linux
```

Build:

```bash
flutter build linux
```

---

## 8. Jalur D — Desktop macOS

```bash
flutter config --enable-macos-desktop
flutter doctor -v
python scripts/payloadhub.py desktop
```

Atau:

```bash
cd frontend
flutter run -d macos
```

Build:

```bash
flutter build macos
```

iOS (opsional, hanya macOS):

```bash
cd frontend
flutter run -d ios
```

---

## 9. Jalur E — Web (Opsional)

```bash
python scripts/payloadhub.py web
```

Atau `cd frontend && flutter run -d chrome`.

Untuk web, backend harus mengizinkan origin. `backend/.env` default
`CORS_ALLOW_ORIGINS=*`; untuk produksi ganti dengan origin web yang spesifik.

---

## 10. Verifikasi Setelah Instalasi

```bash
# Tool dan perangkat
python scripts/payloadhub.py doctor
flutter devices

# Kualitas kode
cd frontend
flutter analyze
flutter test

# Backend
curl http://127.0.0.1:8000/healthz
```

Checklist aplikasi:

- [ ] Aplikasi terbuka tanpa crash.
- [ ] Bottom navigation (HP) atau sidebar (desktop) berfungsi.
- [ ] Generator menerima `10.10.14.8:9001` dan menghasilkan payload.
- [ ] Payload masuk ke Riwayat Aktivitas.
- [ ] Settings menyimpan LHOST/LPORT.
- [ ] Jika memakai AI: Info Bot menjawab atau backend mengembalikan 200.
- [ ] Jika memakai HP fisik: URL backend sudah diisi dari Settings.

---

## 11. Troubleshooting

| Gejala | Penyebab | Solusi |
|---|---|---|
| `flutter` tidak dikenali | PATH belum diatur | Tambahkan `flutter/bin` ke PATH, buka terminal baru |
| `No devices found` | Emulator/HP belum aktif | Nyalakan emulator atau aktifkan USB debugging |
| `Gradle task assembleRelease failed` | JDK tidak cocok | Pakai JDK 20, `flutter config --jdk-dir=...` |
| `Visual Studio not found` | Workload C++ belum ada | Install workload Desktop development with C++ |
| Linux: `ninja`/`gtk` hilang | Paket belum lengkap | Jalankan apt pada Bagian 1.6 |
| macOS: `pod` tidak ada | CocoaPods belum ada | `sudo gem install cocoapods` |
| Backend connection refused | Uvicorn tidak jalan | Jalankan `python scripts/payloadhub.py backend` |
| HP tidak bisa connect | URL/firewall/Wi-Fi | Gunakan IP LAN, port 8000, Wi-Fi sama |
| Emulator tidak bisa connect | Memakai `localhost` | Gunakan `10.0.2.2:8000` |
| AI error 401/403 | Key salah/kosong | Isi `backend/.env` atau Settings, restart |
| APK tidak bisa install | Sumber tidak dikenal | Izinkan install unknown apps |
| `flutter pub get` lambat | Jaringan/registry | Ulangi; cek proxy/VPN |

Jika masih gagal, jalankan:

```bash
python scripts/payloadhub.py doctor > doctor.txt
flutter doctor -v >> doctor.txt
```

Sertakan `doctor.txt` saat bertanya, **tanpa** menyertakan API key.

---

## 12. Update dan Bersih-bersih

Update source:

```bash
git pull origin main
python scripts/payloadhub.py setup
```

Bersihkan build:

```bash
cd frontend
flutter clean
flutter pub get
```

Hapus setup lokal (opsional):

```bash
rm -rf backend/.venv backend/.env frontend/build frontend/.dart_tool
```

Di Windows PowerShell:

```powershell
Remove-Item -Recurse -Force backend\.venv, backend\.env, frontend\build, frontend\.dart_tool
```

---

## 13. Keamanan

- Jangan commit `backend/.env`, `key.properties`, `*.jks`, atau file `api-*`.
- API key di aplikasi disimpan lewat `flutter_secure_storage`.
- Untuk distribusi publik, buat keystore rilis; APK rilis saat ini memakai
  debug key untuk demo.
- Gunakan hanya pada lab, CTF, atau target dengan izin tertulis.
