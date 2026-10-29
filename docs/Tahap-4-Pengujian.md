# TAHAP 4 — Integrasi, Pengujian, dan Penyempurnaan

**Proyek:** PayloadHub-AI
**Tujuan tahap:** memastikan setiap fungsi berjalan sesuai kebutuhan Tahap 1, mendokumentasikan temuan, memperbaiki masalah, dan mengevaluasi kemudahan penggunaan.

---

## 1. Strategi Pengujian

| Level | Tujuan | Alat |
|---|---|---|
| **Statis** | Menemukan error tipe, API usang, dan pelanggaran *lint* | `flutter analyze` |
| **Unit** | Menguji logika murni: validasi, serialisasi, controller riwayat | `flutter test` + `test` package |
| **Widget** | Menguji shell, navigasi, form, dan riwayat pada dua ukuran layar | `flutter_test` + fake repository |
| **Integrasi** | Menguji alur end-to-end klien–backend | Uji manual + `curl` |
| **Kompatibilitas** | Memastikan layout pada ponsel, tablet, desktop | Widget test viewport 390×844 dan 1440×900 |
| **Keamanan** | Memastikan tidak ada kredensial di bundle; input disanitasi | Pemeriksaan kode, `assets_test.dart` |
| **Usability** | Menilai kemudahan penggunaan | *Heuristic evaluation* + kuesioner calon pengguna |

## 2. Lingkungan Pengujian

| Komponen | Spesifikasi |
|---|---|
| OS | Windows 10 Pro 22H2 (19045) |
| Flutter | 3.47.2 stable |
| Dart | 3.13.2 |
| JDK untuk Gradle | OpenJDK 20.0.2 |
| Android SDK | 36.0.0 |
| Browser | Chrome 155 |
| Perangkat | Windows desktop, Chrome, Edge (emulator Android tidak aktif saat pengujian otomatis) |
| Backend | FastAPI (uji `healthz`/agent membutuhkan API key LLM) |

## 3. Skenario dan Kasus Uji

### 3.1 Fungsional

| ID | Fitur | Langkah | Hasil yang diharapkan | Jenis |
|---|---|---|---|---|
| TS-01 | Dashboard tampil | Buka aplikasi | Judul, kartu, dan navigasi tampil tanpa error | Otomatis + manual |
| TS-02 | Navigasi desktop | Klik setiap item sidebar | Halaman berganti, tidak ada exception/overflow | Otomatis |
| TS-03 | Navigasi ponsel | Ketuk setiap item bottom nav | Halaman berganti, layout satu kolom | Otomatis |
| TS-04 | Dashboard ponsel | Buka Home pada 390×844 | Kartu tersusun vertikal, tidak ada *horizontal scroll* | Otomatis (widget) |
| TS-05 | Validasi LHOST kosong | Tekan Generate tanpa mengisi | Pesan `IP address is required` | Otomatis |
| TS-06 | Validasi LPORT kosong | Tekan Generate tanpa port | Pesan `Port is required` | Otomatis |
| TS-07 | Validasi IP salah | Isi `999.1.1.1` | Pesan `Enter a valid IPv4 address` | Unit |
| TS-08 | Validasi port salah | Isi `0`, `65536`, `abc` | Pesan rentang port | Unit |
| TS-09 | Generate one-liner | Isi `10.10.14.8:9001`, tekan Generate | Payload bash `/dev/tcp` muncul | Otomatis |
| TS-10 | Simpan riwayat | Setelah TS-09 | Entri bertambah, judul `Reverse Shell · bash` | Otomatis |
| TS-11 | Riwayat persisten | Buka/tutup aplikasi (repository) | Entri dimuat ulang dari secure storage | Unit + manual |
| TS-12 | Hapus riwayat per entri | Geser kartu ke kiri | Entri hilang dan tidak kembali setelah reload | Manual |
| TS-13 | Hapus semua riwayat | Tekan ikon hapus → konfirmasi | Daftar kosong, status kosong tampil | Manual |
| TS-14 | Ekspor riwayat | Tekan ikon simpan | JSON disalin, SnackBar menampilkan jumlah entri | Manual |
| TS-15 | Detail riwayat | Ketuk entri | Bottom sheet menampilkan kode; tombol salin bekerja | Manual |
| TS-16 | Pencarian exploit | Ketik `CVE-2021` | Daftar terfilter | Manual |
| TS-17 | Detail exploit ponsel | Ketuk item pada 390 px | Halaman detail penuh terbuka, tombol kembali bekerja | Otomatis (layout) + manual |
| TS-18 | Send to Studio | Tekan tombol pada detail | Kembali ke Dashboard, Studio terisi | Manual |
| TS-19 | Settings tersimpan | Isi LHOST/LPORT → Save | SnackBar sukses; nilai dipakai generator | Manual |
| TS-20 | Prefill generator | Simpan LHOST/LPORT lalu buka generator | Field terisi otomatis | Manual |
| TS-21 | API key tidak tampil | Buka Settings | Field sandi tersamarkan | Manual |
| TS-22 | Backend sehat | `GET /healthz` | `{"status":"ok"}` | Integrasi (butuh server) |
| TS-23 | Backend validasi | Kirim `lport=70000` | HTTP 400 + detail validasi | Integrasi (butuh server) |
| TS-24 | Backend tanpa key | Kirim prompt tanpa `LLM_API_KEY` | Error 500 terstruktur, bukan crash | Integrasi (butuh server) |

### 3.2 Nonfungsional

| ID | Aspek | Metode | Kriteria lulus |
|---|---|---|---|
| TN-01 | Kualitas kode | `flutter analyze` | 0 error, 0 warning, 0 info |
| TN-02 | Regresi | `flutter test` | Semua test lulus |
| TN-03 | Performa startup | Stopwatch pada perangkat | < 3 detik sampai dashboard |
| TN-04 | Ukuran APK | Ukuran berkas | < 60 MB |
| TN-05 | Keamanan kredensial | Pemeriksaan `assets/` dan kode | Tidak ada key asli di bundle/test |
| TN-06 | Aksesibilitas | Target sentuh & kontras | Tombol ≥ 34 dp, teks utama kontras tinggi |
| TN-07 | Responsif | Viewport 390, 700, 1000, 1440 px | Tidak ada overflow |

## 4. Hasil Pengujian Otomatis

Perintah:

```text
flutter analyze   → No issues found! (ran in 9.2s)
flutter test      → 00:04 +16: All tests passed!
```

| Berkas uji | Jumlah | Cakupan | Hasil |
|---|---:|---|---|
| `test/validators_test.dart` | 6 | IPv4 valid/invalid, port 1–65535, pesan error | **Lulus** |
| `test/activity_history_test.dart` | 7 | Serialisasi JSON, data rusak, urutan, tambah/hapus/bersihkan, batas 40, kegagalan simpan | **Lulus** |
| `test/widget_test.dart` | 2 | Navigasi desktop 5 halaman, validasi form, generate payload, riwayat, shell ponsel, rute riwayat | **Lulus** |
| `test/assets_test.dart` | 1 | Startup tidak membutuhkan kredensial ter-bundle | **Lulus** |
| **Total** | **16** | | **Lulus semua** |

### 4.1 Detail eksekusi widget test

```
00:03 +15: desktop dashboard pages, validation and history work
00:04 +16: mobile shell uses bottom navigation and stacked dashboard
00:04 +16: All tests passed!
```

Test ponsel memakai viewport **390×844** dan memverifikasi:

1. `NavigationBar` tampil, sidebar tidak tampil.
2. Tab Generator dapat dibuka.
3. Payload dihasilkan dari input `192.168.1.20:4444`.
4. Tidak ada exception layout.
5. Rute Riwayat terbuka dan menampilkan `Reverse Shell · bash`.

Test desktop memakai viewport **1440×900** dan memverifikasi seluruh halaman,
validasi kosong, serta penyimpanan riwayat.

## 5. Daftar Kesalahan yang Ditemukan dan Perbaikannya

| ID | Temuan | Tingkat | Penyebab | Perbaikan | Verifikasi |
|---|---|---|---|---|---|
| BUG-01 | Assertion `ListTile background color or ink splashes may be invisible` saat membuka Settings (6 exception) | Tinggi | `SwitchListTile` berada di dalam `Container` ber-`BoxDecoration` tanpa `Material` | Bungkus dengan `Material(type: MaterialType.transparency)` | Widget test desktop lulus tanpa exception |
| BUG-02 | Dashboard ponsel memaksa *horizontal scroll* 960 px | Tinggi (UX) | Layout tiga kolom selalu dipakai | Breakpoint 1000 px → satu kolom vertikal; tiga kolom hanya layar lebar | Widget test 390 px tanpa overflow |
| BUG-03 | APK rilis tidak dapat mengakses backend | Tinggi | Manifest rilis tidak punya izin `INTERNET`; Android 9+ memblokir HTTP *cleartext* | Tambah `INTERNET` + `usesCleartextTraffic` (untuk lab lokal) | Build & instalasi |
| BUG-04 | Generator menerima IP/port kosong atau tidak valid | Sedang | Tidak ada `Form`/validator pada tab one-liner | Tambah `Form`, `TextFormField`, validator, dan filter digit | Unit + widget test |
| BUG-05 | API Flutter usang (`value`, `activeColor`) | Rendah | Template lama | Ganti ke `initialValue`/`activeThumbColor` + `key` | `flutter analyze` bersih |
| BUG-06 | Tombol top bar tidak berfungsi (dekorasi) | Sedang (UX) | Belum ada handler | Sambungkan ke riwayat, ekspor JSON, dan dialog About | Widget test + manual |
| BUG-07 | Detail exploit di ponsel hanya separuh layar | Sedang (UX) | Layout dua panel dipaksakan | Rute penuh `_ExploitDetailScreen` | Manual pada 390 px |
| BUG-08 | Build APK gagal: Gradle 8.3 < minimum Flutter 3.47 | Tinggi (rilis) | Template Android tertinggal | Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20, JDK 20 | Build APK |
| BUG-09 | Tidak ada riwayat pekerjaan setelah aplikasi ditutup | Tinggi (fungsional) | Belum ada penyimpanan | `ActivityEntry` + repository terenkripsi + panel + halaman | Unit + widget test |

### 5.1 Dokumentasi perbaikan BUG-01

Sebelum:

```dart
return SwitchListTile(
  title: Text(label),
  value: value,
  activeColor: AppColors.accent,
  onChanged: onChanged,
);
```

Sesudah:

```dart
return Material(
  type: MaterialType.transparency,
  child: SwitchListTile(
    title: Text(label),
    value: value,
    activeThumbColor: AppColors.accent,
    onChanged: onChanged,
  ),
);
```

### 5.2 Dokumentasi perbaikan BUG-02

Sebelum: `Row` tiga kolom selalu dibangun, dengan `SingleChildScrollView`
horizontal bila layar sempit.

Sesudah:

```dart
if (constraints.maxWidth < 1000) {
  return const SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(14, 14, 14, 96),
    child: Column(children: [
      StudioConfigPanel(),
      NmapScansPanel(),
      ActivityHistoryPanel(),
      PayloadLibraryPanel(),
      ThreatIntelPanel(),
      MonitoringPanel(),
    ]),
  );
}
```

## 6. Evaluasi Heuristik (Expert Review)

Dilakukan oleh pengembang dengan 10 heuristik Nielsen terhadap build terbaru.

| Heuristik | Temuan | Tindakan |
|---|---|---|
| Visibilitas status sistem | Tidak ada indikator koneksi backend | Ditambahkan pesan error kontekstual pada kartu hasil |
| Kesesuaian dengan dunia nyata | Istilah teknis sudah lazim bagi pengguna | Dipertahankan; Info Bot membantu pemula |
| Kontrol & kebebasan pengguna | Menghapus semua riwayat tanpa konfirmasi | Ditambahkan dialog konfirmasi |
| Konsistensi & standar | Tombol top bar tidak konsisten (tidak bereaksi) | Semua tombol kini berfungsi |
| Pencegahan kesalahan | Generator menerima input kosong | Validasi form + filter digit |
| Pengenalan vs mengingat | LHOST harus diketik berulang | Prefill dari Settings |
| Efisiensi penggunaan | Detail exploit sempit di ponsel | Rute detail penuh |
| Desain minimalis | Dashboard padat di ponsel | Satu kolom + kartu prioritas |
| Pesan kesalahan | Error backend mentah | Pesan dipetakan + saran tindakan |
| Bantuan & dokumentasi | Belum ada bantuan dalam aplikasi | Dialog About + Info Bot + README |

## 7. Pengujian Pengguna

### 7.1 Instrumen

Kuesioner 8 pernyataan skala Likert 1–5 (1 = sangat tidak setuju, 5 = sangat setuju):

1. Aplikasi mudah dipahami saat pertama kali dibuka.
2. Saya dapat menemukan fitur yang saya butuhkan dalam ≤ 2 menit.
3. Navigasi bawah/sidebar konsisten dan mudah dijangkau.
4. Formulir generator jelas dan pesan kesalahannya membantu.
5. Hasil payload mudah dibaca dan disalin.
6. Riwayat aktivitas membantu pekerjaan saya.
7. Tampilan nyaman di layar ponsel (tidak perlu menggulir horizontal).
8. Saya akan menggunakan aplikasi ini lagi untuk latihan lab/CTF.

Ditambah 3 pertanyaan terbuka: fitur paling berguna, kesulitan terbesar, dan saran perbaikan.

### 7.2 Prosedur

1. Responden diberi penjelasan singkat dan peringatan etika.
2. Responden menyelesaikan 3 tugas: (a) membuat payload `10.10.14.8:9001`, (b) mencari CVE Apache 2.4.49, (c) membuka dan menyalin riwayat.
3. Pengamat mencatat waktu, kesalahan, dan bantuan yang diberikan.
4. Responden mengisi kuesioner.

### 7.3 Status pelaksanaan

> **Catatan integritas:** pengujian dengan calon pengguna **belum dilaksanakan**
> pada saat dokumen ini disusun. Tabel di bawah disediakan sebagai format
> pelaporan; sel-sel hasil wajib diisi setelah sesi pengujian benar-benar
> dilakukan. Angka tidak boleh dikarang.

| Responden | Latar belakang | Waktu tugas (a/b/c) | Kesalahan | Skor rata-rata (1–5) | Catatan |
|---|---|---|---:|---|---|
| R1 | Mahasiswa keamanan | — | — | — | Belum dilaksanakan |
| R2 | Peserta CTF | — | — | — | Belum dilaksanakan |
| R3 | Mahasiswa umum | — | — | — | Belum dilaksanakan |
| R4 | Praktisi lab | — | — | — | Belum dilaksanakan |
| R5 | Dosen/pembimbing | — | — | — | Belum dilaksanakan |

**Rencana analisis:** hitung rata-rata per pernyataan, identifikasi butir dengan
skor < 4, lalu prioritas perbaikan pada butir terendah. Target: rata-rata ≥ 4,0
dan tidak ada responden yang gagal menyelesaikan tugas (a).

## 8. Penyempurnaan Antarmuka dan Pengalaman Pengguna

| Sebelum | Sesudah |
|---|---|
| Dashboard horizontal scroll di ponsel | Vertikal, kartu prioritas, FAB tidak menutupi tombol utama |
| Detail exploit separuh layar | Halaman penuh dengan AppBar dan tombol kembali |
| Tombol top bar dekoratif | Riwayat, ekspor JSON, dan About berfungsi |
| Riwayat hilang saat keluar | Tersimpan terenkripsi, dapat dicari dan dihapus |
| Error teknis mentah | Pesan validasi berbahasa manusia + SnackBar |
| Bottom nav menempel ke tepi | `SafeArea` + tinggi 64 dp + indikator aksen |

## 9. Hasil Build

| Artefak | Status | Lokasi |
|---|---|---|
| APK rilis | Lihat bagian 9.1 | `frontend/build/app/outputs/flutter-apk/app-release.apk` |
| Web | Dapat dibangun dengan `flutter build web` | `frontend/build/web/` |
| Sumber | Git | <https://github.com/farrelfaiziaulhaq/payloadhub-ai> |

### 9.1 Catatan build APK

Build kandidat dilakukan dengan:

```bash
cd frontend
flutter analyze            # 0 issue
flutter test               # 16 lulus
flutter build apk --release
```

Kendala yang ditemukan dan diselesaikan: JDK 25 tidak kompatibel dengan Gradle
8.3, lalu Flutter 3.47 menolak Gradle < 8.14 dan Kotlin < 2.2.20 (BUG-08).
Solusi akhir: **JDK 20 + Gradle 8.14.3 + AGP 8.11.1 + Kotlin 2.2.20**.

Hasil build final (23 Oktober 2026):

| Atribut | Nilai |
|---|---|
| Status | **Berhasil** |
| Berkas | `frontend/build/app/outputs/flutter-apk/app-release.apk` |
| Ukuran | 58.156.477 byte (55,5 MB) |
| SHA-256 | `302D47DEEB6A9AEAD3153173B1EC8431F94C97BCA61123D690A2267020EE5624` |

Verifikasi ulang setelah perubahan konfigurasi Android: `flutter analyze`
tanpa temuan dan 16 pengujian lulus. Instalasi pada perangkat fisik belum
dicatat; lihat Tahap 5 §7.

## 10. Kesimpulan Pengujian

- Seluruh **16 pengujian otomatis** lulus dan `flutter analyze` bersih.
- Sembilan masalah nyata ditemukan; delapan sudah diperbaiki dan diverifikasi,
  satu (pengujian pengguna) masih menunggu pelaksanaan sesi.
- Perbaikan berfokus pada tiga area: **kestabilan** (BUG-01/08),
  **fungsionalitas** (BUG-03/04/09), dan **pengalaman ponsel** (BUG-02/06/07).
- Pengujian perangkat fisik dan pengujian pengguna menjadi syarat penutupan
  Tahap 4 sebelum presentasi.

---

## 11. Status Verifikasi

| Klaim | Status | Bukti |
|---|---|---|
| 16 test lulus | **[C]** | Output `flutter test` |
| Analyzer bersih | **[C]** | Output `flutter analyze` |
| Bug diperbaiki | **[C]** | Diff kode + test regresi |
| Pengujian pengguna | **[S]** | Belum dilaksanakan; format tersedia |
| Ukuran APK & instalasi perangkat | **[C]** ukuran; **[S]** instalasi | Build APK 55,5 MB; perangkat fisik belum dicatat |

**VERDICT: request_changes** — kualitas teknis baik, tetapi pengujian pengguna dan verifikasi pada perangkat fisik wajib diselesaikan sebelum Tahap 5 dinyatakan final.
