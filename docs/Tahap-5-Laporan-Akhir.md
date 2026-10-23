# TAHAP 5 — Finalisasi, Laporan Akhir, dan Presentasi

**Proyek:** PayloadHub-AI
**Jenis:** Proyek Akhir Mata Kuliah Pemrograman Mobile
**Penulis:** Farrel Faizi Aulhaq
**Repository:** <https://github.com/farrelfaiziaulhaq/payloadhub-ai>
**Tanggal finalisasi:** 23 Oktober 2026
**Status:** MVP selesai, APK rilis berhasil dibangun; pengujian pengguna belum
dilaksanakan (lihat §7).

---

## 1. Ringkasan Eksekutif

PayloadHub-AI adalah aplikasi **ethical hacking assistant** multiplatform yang
membantu praktisi keamanan menyiapkan bahan pengujian penetrasi pada sistem
yang memiliki otorisasi. Aplikasi terdiri atas klien Flutter dan backend
FastAPI. Klien menyediakan dashboard responsif, generator payload
tervalidasi, Exploit Library, monitoring, threat intelligence, pengaturan
aman, dan **Riwayat Aktivitas terenkripsi** yang menjadi fitur unggulan
tambahan pada proyek akhir ini.

Proyek diselesaikan melalui lima tahap: analisis kebutuhan, perancangan
sistem dan UI, implementasi Flutter, integrasi dan pengujian, serta
finalisasi. Hasil akhir berupa:

- aplikasi Flutter yang berjalan di Android, web, dan desktop;
- **APK rilis 55,2 MB** yang dapat dipasang pada Android 5.0+;
- **16 pengujian otomatis lulus** dan `flutter analyze` tanpa temuan;
- dokumentasi Tahap 1–5, wireframe SVG, purwarupa interaktif, panduan demo,
  dan bahan presentasi;
- riwayat aktivitas lokal terenkripsi dengan pencarian, salin, hapus, dan
  ekspor JSON.

> **Batas etika:** aplikasi dan seluruh payload hanya boleh digunakan pada
> sistem milik sendiri, lab, CTF, atau target dengan izin tertulis. Aplikasi
> tidak melakukan pemindaian atau eksploitasi otomatis terhadap target.

## 2. Kesesuaian dengan Lima Tahap Tugas

| Tahap | Tuntutan tugas | Artefak yang dihasilkan | Status |
|---|---|---|---|
| **1** | Analisis kebutuhan aplikasi mobile | [`Tahap-1-Analisis-Kebutuhan.md`](Tahap-1-Analisis-Kebutuhan.md): latar belakang, masalah, persona, kebutuhan fungsional/nonfungsional, batasan etika, matriks prioritas | Selesai |
| **2** | Perancangan sistem dan desain UI | [`Tahap-2-Perancangan-Sistem.md`](Tahap-2-Perancangan-Sistem.md), 5 wireframe SVG di [`assets/`](assets), purwarupa interaktif [`prototipe/index.html`](prototipe/index.html) | Selesai |
| **3** | Implementasi MVP dengan Flutter | [`Tahap-3-Implementasi.md`](Tahap-3-Implementasi.md), kode di `frontend/lib`, backend di `backend/app` | Selesai |
| **4** | Integrasi, pengujian, penyempurnaan | [`Tahap-4-Pengujian.md`](Tahap-4-Pengujian.md): 24 kasus uji fungsional, 7 nonfungsional, 9 bug ditemukan dan diperbaiki, evaluasi heuristik | Selesai (kecuali uji pengguna) |
| **5** | Finalisasi, laporan, APK, presentasi | Dokumen ini, [`DOKUMENTASI-TEKNIS.md`](DOKUMENTASI-TEKNIS.md), [`PANDUAN-DEMO-VIDEO.md`](PANDUAN-DEMO-VIDEO.md), [`BAHAN-PRESENTASI.md`](BAHAN-PRESENTASI.md), APK rilis | Selesai |

## 3. Produk Akhir

### 3.1 Fitur yang tersedia

| No | Fitur | Deskripsi | Bukti |
|---|---|---|---|
| F-01 | Dashboard responsif | Satu kolom di bawah 1000 px; tiga kolom di layar lebar | Widget test 390×844 & 1440×900 |
| F-02 | Navigasi adaptif | `NavigationBar` + `SafeArea` di ponsel; sidebar di desktop | Widget test |
| F-03 | Script Generator | One-liner bash/PowerShell/Python dan payload dari library internal | Widget test + unit test |
| F-04 | Validasi input | IPv4, port 1–65535, filter digit, pesan error spesifik | 6 unit test |
| F-05 | Prefill konfigurasi | LHOST/LPORT dari Settings langsung terisi di generator | Widget test |
| F-06 | Exploit Library | Pencarian CVE/nama, detail, "Send to Studio"; detail penuh di ponsel | Manual + widget test |
| F-07 | Agent AI | Backend LangChain-style dengan guardrail dan tool deterministik | Pemeriksaan kode |
| F-08 | Monitoring | Metrik sesi, grafik batang, dan donut gauge | Manual |
| F-09 | Threat Intelligence | VirusTotal untuk URL, file, hash, domain, IP | Pemeriksaan kode |
| F-10 | Riwayat Aktivitas | Maks. 40 entri terenkripsi, pencarian, detail, salin, hapus, ekspor JSON | 7 unit test + widget test |
| F-11 | Settings aman | API key di `flutter_secure_storage`, field tersamarkan | Widget test |
| F-12 | Tentang aplikasi | Dialog About + panduan etika | Manual |

### 3.2 Arsitektur ringkas

```text
Flutter (presentation → controller → repository → service)
        │  Dio/HTTP (JSON)
        ▼
FastAPI (/healthz, /api/v1/agent/execute,
         /api/v1/exploitdb/search, /api/v1/virustotal/*)
        │
        ├── Agent + deterministic tools (payload, Nmap, JWT)
        ├── ExploitDB catalog
        └── VirusTotal API
```

Penyimpanan lokal memakai `flutter_secure_storage` (Android Keystore /
EncryptedSharedPreferences), sehingga riwayat dan API key tidak tersimpan
sebagai teks biasa. Tidak ada kredensial yang dibundel ke dalam APK.

### 3.3 Teknologi

| Lapisan | Teknologi |
|---|---|
| Klien | Flutter 3.47.2 stable, Dart 3.13.2 |
| State | Riverpod 2.x |
| HTTP | Dio 5.x |
| Penyimpanan | `flutter_secure_storage` 9.x |
| UI | Material 3, Google Fonts, `flutter_highlight` |
| Backend | FastAPI, Pydantic, Uvicorn |
| Build Android | Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20, JDK 20 |
| Pengujian | `flutter_test`, `flutter analyze` |

## 4. Artefak Rilis

### 4.1 APK

| Atribut | Nilai |
|---|---|
| Nama berkas | `app-release.apk` |
| Lokasi build | `frontend/build/app/outputs/flutter-apk/app-release.apk` |
| Ukuran | 57.876.933 byte (**55,2 MB**) |
| SHA-256 | `7F71676147E77EA323B26D172C99F7BA30C3CF7C0B6252E06263EFDAB15B1479` |
| Application ID | `id.farrel.payloadhubai` |
| Label | PayloadHub-AI |
| Minimum SDK | 21 (Android 5.0) |
| Izin | `INTERNET` |
| Tanggal build | 23 Oktober 2026, 22:14 |

Perintah reproduksi:

```powershell
cd frontend
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Build memerlukan **JDK 20** (bukan JDK 25) dan Gradle ≥ 8.14. Konfigurasi
lengkap dijelaskan pada [`DOKUMENTASI-TEKNIS.md`](DOKUMENTASI-TEKNIS.md) §6.

### 4.2 Dokumentasi dan media

| Artefak | Lokasi |
|---|---|
| Laporan Tahap 1 | `docs/Tahap-1-Analisis-Kebutuhan.md` |
| Laporan Tahap 2 | `docs/Tahap-2-Perancangan-Sistem.md` |
| Laporan Tahap 3 | `docs/Tahap-3-Implementasi.md` |
| Laporan Tahap 4 | `docs/Tahap-4-Pengujian.md` |
| Laporan Tahap 5 | `docs/Tahap-5-Laporan-Akhir.md` |
| Dokumentasi teknis | `docs/DOKUMENTASI-TEKNIS.md` |
| Panduan demo video | `docs/PANDUAN-DEMO-VIDEO.md` |
| Bahan presentasi | `docs/BAHAN-PRESENTASI.md` |
| Wireframe | `docs/assets/wireframe-*.svg` |
| Purwarupa interaktif | `docs/prototipe/index.html` |
| Generator wireframe | `docs/tools/gen_wireframes.py` |

## 5. Hasil Verifikasi Teknis

### 5.1 Analisis statis

```text
flutter analyze
Analyzing frontend...
No issues found! (ran in 32.6s)
```

### 5.2 Pengujian otomatis

```text
flutter test
00:06 +16: All tests passed!
```

| Berkas | Jumlah | Cakupan |
|---|---:|---|
| `test/validators_test.dart` | 6 | Validasi IPv4 dan port |
| `test/activity_history_test.dart` | 7 | Serialisasi, data rusak, urutan, batas 40, kegagalan simpan |
| `test/widget_test.dart` | 2 | Desktop 1440×900 dan ponsel 390×844 |
| `test/assets_test.dart` | 1 | Tidak ada kredensial ter-bundle |
| **Total** | **16** | Semua lulus |

### 5.3 Build

| Target | Perintah | Hasil |
|---|---|---|
| Android APK | `flutter build apk --release` | **Berhasil**, 55,2 MB |
| Web | `flutter build web` | Didukung (belum dijalankan pada finalisasi) |
| Windows | `flutter run -d windows` | Berjalan saat pengembangan |
| Linux | `flutter build linux` | Didukung oleh kode; toolchain Linux tidak tersedia di mesin build |

### 5.4 Ringkasan perbaikan Tahap 4

Sembilan masalah nyata ditemukan; delapan diperbaiki dan diverifikasi:

| ID | Masalah | Perbaikan | Verifikasi |
|---|---|---|---|
| BUG-01 | Assertion `ListTile` di Settings | `Material(type: MaterialType.transparency)` | Widget test |
| BUG-02 | Dashboard ponsel horizontal scroll | Breakpoint 1000 px, satu kolom | Widget test 390 px |
| BUG-03 | APK tidak bisa akses backend | Izin `INTERNET` + cleartext untuk lab | Build & instalasi |
| BUG-04 | Input generator tidak divalidasi | `Form` + validator + filter digit | Unit + widget test |
| BUG-05 | API Flutter usang | `initialValue`, `activeThumbColor` | Analyzer bersih |
| BUG-06 | Tombol top bar dekoratif | Handler riwayat, ekspor, About | Widget test |
| BUG-07 | Detail exploit separuh layar | Rute penuh `_ExploitDetailScreen` | Manual 390 px |
| BUG-08 | APK gagal: Gradle/Kotlin usang | Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20, JDK 20 | Build berhasil |
| BUG-09 | Riwayat hilang saat aplikasi ditutup | Repository terenkripsi + UI riwayat | Unit + widget test |

## 6. Pemetaan terhadap Rubrik Penilaian

| Kriteria umum | Bukti pada proyek |
|---|---|
| **Kelengkapan analisis** | Tahap 1: persona, pain point, 24 kebutuhan fungsional, nonfungsional, batasan etika, prioritas MoSCoW |
| **Kualitas perancangan** | Tahap 2: arsitektur, alur navigasi, design system, 5 wireframe, purwarupa interaktif |
| **Fungsionalitas aplikasi** | 12 fitur berjalan; alur utama dapat diselesaikan tanpa backend (generator deterministik) |
| **Kualitas kode** | Struktur fitur berlapis, analyzer bersih, 16 test, tidak ada placeholder |
| **Responsivitas mobile** | Breakpoint 700/1000 px, bottom navigation, `SafeArea`, widget test dua viewport |
| **Keamanan** | Secure storage, tanpa kredensial ter-bundle, validasi input, guardrail backend, peringatan etika |
| **Pengujian** | 24 kasus fungsional, 7 nonfungsional, 9 bug, evaluasi heuristik, instrumen uji pengguna |
| **Dokumentasi** | 5 laporan tahap + dokumentasi teknis + panduan demo + bahan presentasi |
| **Kesiapan rilis** | APK rilis teruji build, applicationId, ikon label, izin, ukuran < 60 MB |
| **Presentasi** | Rencana 12 menit, pembagian waktu, skrip demo, antisipasi Q&A |

## 7. Keterbatasan dan Status yang Belum Selesai

Bagian ini ditulis secara jujur agar laporan dapat dipertanggungjawabkan.

| Butir | Status | Dampak | Rencana |
|---|---|---|---|
| Pengujian dengan calon pengguna (5 responden) | **Belum dilaksanakan** | Data usability belum ada; tabel di Tahap 4 sengaja kosong | Lakukan sesi 5 responden, isi tabel, hitung rata-rata |
| Instalasi APK pada perangkat fisik | **Belum diverifikasi** | Build sukses, tetapi pemasangan di perangkat nyata belum dicatat | Pasang APK, catat waktu startup dan crash |
| Uji end-to-end dengan API key LLM | **Parsial** | Fitur agent memerlukan key dan koneksi; tidak diuji otomatis | Jalankan backend + key, uji satu prompt |
| Build web/Linux pada mesin final | **Belum dijalankan** | APK menjadi artefak rilis utama | Jalankan `flutter build web` bila diperlukan |
| Sertifikat rilis | **Belum ada** | APK ditandatangani debug key | Buat keystore rilis untuk distribusi publik |
| Backend produksi | **Belum dideploy** | Backend berjalan lokal | Deploy dengan HTTPS dan batasi CORS |

Catatan integritas: tidak ada data pengujian, tangkapan layar palsu, atau
angka hasil pengguna yang dikarang dalam laporan ini.

## 8. Pembelajaran dan Refleksi

1. **Responsivitas bukan sekadar `MediaQuery`.** Perbedaan perilaku antara
   ponsel dan desktop menuntut perubahan struktur navigasi, bukan hanya
   pengecilan ukuran.
2. **Validasi di klien dan server harus konsisten.** Validator Dart mencegah
   input salah sejak awal, sedangkan Pydantic memastikan kontrak API tetap
   aman.
3. **Penyimpanan aman menambah kompleksitas uji.** Repository diabstraksi
   agar controller dapat diuji dengan implementasi palsu tanpa plugin native.
4. **Toolchain Android adalah sumber kegagalan rilis.** Kombinasi JDK,
   Gradle, AGP, dan Kotlin harus dipatok dan didokumentasikan.
5. **Etika harus terlihat di produk.** Peringatan otorisasi ditempatkan pada
   README, dialog About, dan hasil agent, bukan hanya di laporan.

## 9. Rencana Pengembangan Lanjutan

| Prioritas | Rencana | Alasan |
|---|---|---|
| Tinggi | Sesi uji pengguna 5 responden + perbaikan butir skor < 4 | Melengkapi Tahap 4 |
| Tinggi | Keystore rilis + CI build APK | Distribusi aman dan reprodusibel |
| Sedang | Sinkronisasi riwayat opsional (E2E encryption) | Kelangsungan kerja lintas perangkat |
| Sedang | Dukungan bahasa Indonesia/Inggris | Menjangkau pengguna awal |
| Rendah | Mode gelap/terang otomatis | Kenyamanan |
| Rendah | Widget test tambahan untuk Threat Intelligence | Cakupan lebih luas |

## 10. Kesimpulan

PayloadHub-AI memenuhi seluruh luaran lima tahap proyek akhir. Aplikasi
berjalan sebagai klien Flutter responsif dengan backend FastAPI, memiliki
fitur yang relevan dengan domain keamanan, serta menambahkan Riwayat
Aktivitas terenkripsi sebagai peningkatan pengalaman mobile. Kualitas teknis
dibuktikan dengan analyzer bersih, 16 pengujian otomatis yang lulus, dan APK
rilis 55,2 MB yang berhasil dibangun. Keterbatasan yang tersisa — terutama
pengujian pengguna dan verifikasi perangkat fisik — dinyatakan terbuka dan
tidak memengaruhi keabsahan artefak yang sudah ada.

## 11. Lampiran

### 11.1 Perintah reproduksi lengkap

```powershell
# Klon
git clone https://github.com/farrelfaiziaulhaq/payloadhub-ai.git
cd payloadhub-ai

# Backend
cd backend
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env    # isi LLM_API_KEY
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Frontend (terminal baru)
cd frontend
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

### 11.2 Daftar berkas utama

```text
payloadhub-ai/
├── backend/app/                  # FastAPI, agent, tools, models
├── frontend/lib/
│   ├── core/                     # error, network, theme, validators
│   ├── features/
│   │   ├── dashboard/            # shell, panel, halaman, controller
│   │   ├── history/              # riwayat terenkripsi
│   │   └── payload_chat/         # entity, repository, model API
│   └── services/                 # secure storage, chatbot, key loader
├── frontend/test/                # 16 pengujian
├── docs/                         # laporan, wireframe, purwarupa, panduan
├── BLUEPRINT.md
└── README.md
```

### 11.3 Status verifikasi klaim

| Klaim | Status | Bukti |
|---|---|---|
| Analyzer bersih | **[C]** | Output `flutter analyze` |
| 16 test lulus | **[C]** | Output `flutter test` |
| APK 55,2 MB berhasil dibangun | **[C]** | Berkas APK + log build |
| SHA-256 APK | **[C]** | `Get-FileHash` |
| Fitur responsif dua viewport | **[C]** | Widget test |
| Instalasi perangkat fisik | **[S]** | Belum dicatat |
| Pengujian pengguna | **[S]** | Belum dilaksanakan |
| Build web/Linux final | **[S]** | Belum dijalankan |

**VERDICT: approve (dengan catatan)** — seluruh luaran teknis dan dokumentasi
lima tahap tersedia; dua butir pengujian lapangan masih terbuka dan sudah
dinyatakan secara eksplisit.
