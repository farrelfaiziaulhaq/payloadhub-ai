# Bahan Presentasi — PayloadHub-AI

**Durasi:** 12 menit presentasi + 5 menit tanya jawab
**Jumlah slide:** 14
**Format:** 16:9
**Pembicara:** Farrel Faizi Aulhaq

---

## 1. Ringkasan Alur

| Slide | Judul | Waktu |
|---:|---|---:|
| 1 | Judul | 0:20 |
| 2 | Latar belakang & masalah | 0:50 |
| 3 | Tujuan & batasan etika | 0:40 |
| 4 | Persona & kebutuhan | 0:50 |
| 5 | Solusi: PayloadHub-AI | 0:50 |
| 6 | Arsitektur sistem | 1:00 |
| 7 | Desain UI & responsivitas | 1:10 |
| 8 | Fitur unggulan: Riwayat terenkripsi | 1:00 |
| 9 | Demo | 3:00 |
| 10 | Pengujian & kualitas | 1:00 |
| 11 | Perbaikan bug | 0:40 |
| 12 | Keterbatasan | 0:40 |
| 13 | Rencana & kesimpulan | 0:40 |
| 14 | Terima kasih / Q&A | 0:20 |

---

## 2. Isi Slide dan Catatan Pembicara

### Slide 1 — Judul

**Isi:**

- **PayloadHub-AI**
- Ethical Hacking Assistant Berbasis Flutter
- Proyek Akhir Pemrograman Mobile
- Farrel Faizi Aulhaq · 2026

**Catatan:**

> “Selamat pagi. Saya Farrel, dan saya akan mempresentasikan PayloadHub-AI,
> aplikasi mobile yang membantu pengujian keamanan yang beretika.”

---

### Slide 2 — Latar Belakang & Masalah

**Isi (3 kartu):**

1. **Repetitif** — payload ditulis ulang setiap sesi.
2. **Rawan salah** — LHOST/LPORT tertukar, port tidak valid.
3. **Tidak terdokumentasi** — catatan sesi hilang setelah aplikasi ditutup.

**Data pendukung:** hasil observasi alur kerja lab/CTF dan analisis aplikasi
serupa; bukan survei formal.

**Catatan:**

> “Tiga masalah utama: pekerjaan berulang, kesalahan konfigurasi, dan tidak
> ada riwayat. Dampaknya waktu terbuang dan pengujian tidak dapat direproduksi.”

---

### Slide 3 — Tujuan & Batasan Etika

**Isi:**

- Tujuan: generator tervalidasi, navigasi mobile, riwayat aman, dokumentasi.
- Batasan:
  - hanya untuk sistem milik sendiri/lab/CTF/izin tertulis;
  - tidak ada pemindaian atau eksploitasi otomatis;
  - tidak ada kredensial di bundle;
  - bukan pengganti penilaian profesional.

**Catatan:**

> “Aplikasi ini adalah alat bantu, bukan senjata otomatis. Peringatan etika
> muncul di README dan dialog About.”

---

### Slide 4 — Persona & Kebutuhan

**Isi:**

| Persona | Kebutuhan utama |
|---|---|
| Mahasiswa keamanan | Alur cepat, contoh jelas, riwayat belajar |
| Peserta CTF | Payload konsisten, salin cepat |
| Praktisi lab | Konfigurasi berulang, dokumentasi sesi |
| Dosen/pembimbing | Bukti proses, etika, kualitas kode |

**Kebutuhan nonfungsional:** responsif 390–1440 px, startup < 3 detik,
APK < 60 MB, tanpa kredensial ter-bundle.

**Catatan:**

> “Empat persona menghasilkan prioritas yang berbeda; fitur riwayat menjawab
> kebutuhan praktisi dan mahasiswa sekaligus.”

---

### Slide 5 — Solusi: PayloadHub-AI

**Isi (fitur):**

- Dashboard responsif
- Script Generator + validasi
- Exploit Library + Send to Studio
- Monitoring
- Threat Intelligence
- **Riwayat Aktivitas terenkripsi**
- Settings aman

**Catatan:**

> “Fitur utama ada tujuh. Yang membedakan proyek ini adalah riwayat
> terenkripsi dan penekanan pada pengalaman ponsel.”

---

### Slide 6 — Arsitektur Sistem

**Isi:** diagram

```text
Flutter (Riverpod, Dio, Secure Storage)
        │ HTTP/JSON
        ▼
FastAPI (Pydantic, Agent, Tools)
        ├── ExploitDB
        └── VirusTotal
```

**Poin:**

- Generator deterministik tetap jalan offline.
- Validasi ganda klien + server.
- Rahasia di secure storage.

**Catatan:**

> “Lapisan presentasi tidak tahu detail HTTP; controller memanggil repository.
> Ini memudahkan pengujian dengan fake repository.”

---

### Slide 7 — Desain UI & Responsivitas

**Isi:** tiga tangkapan/wireframe:

- 390 px: satu kolom, bottom navigation, SafeArea.
- 1000 px: sidebar + tiga kolom.
- Detail exploit: rute penuh di ponsel.

**Catatan:**

> “Breakpoint tujuh ratus dan seribu piksel. Kami tidak hanya mengecilkan
> layout; struktur navigasi berubah.”

---

### Slide 8 — Fitur Unggulan: Riwayat Terenkripsi

**Isi:**

- `ActivityEntry`: id, jenis, judul, detail, waktu.
- Maksimal 40 entri; urut terbaru.
- Disimpan di `flutter_secure_storage`.
- Aksi: cari, detail, salin, hapus, ekspor JSON.
- Parser defensif: data rusak tidak membuat aplikasi crash.

**Catatan:**

> “Payload bisa sensitif, jadi riwayat memakai backend terenkripsi yang sama
> dengan API key. Tujuh unit test mencakup serialisasi dan kegagalan simpan.”

---

### Slide 9 — Demo

**Isi:** daftar 5 langkah:

1. Dashboard potret → navigasi.
2. Generator: validasi → payload → riwayat.
3. Riwayat: detail, salin, hapus, ekspor, persistensi.
4. Exploit Library: pencarian → detail → Send to Studio.
5. Settings: key tersamarkan → prefill.

**Catatan:**

> “Demo mengikuti panduan di PANDUAN-DEMO-VIDEO.md. Jika jaringan bermasalah,
> saya akan menunjukkan generator deterministik dan riwayat.”

**Cadangan:** video demo 3 menit bila live demo gagal.

---

### Slide 10 — Pengujian & Kualitas

**Isi:**

| Metrik | Hasil |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 16 lulus |
| Kasus uji fungsional | 24 |
| Kasus nonfungsional | 7 |
| Bug ditemukan | 9 |
| APK | 55,5 MB, build berhasil |

**Catatan:**

> “Pengujian mencakup unit, widget dua viewport, dan pemeriksaan aset.
> Pengujian pengguna masih terbuka dan akan saya sampaikan di slide
> keterbatasan.”

---

### Slide 11 — Perbaikan Bug Penting

**Isi (pilih 4):**

| Bug | Dampak | Perbaikan |
|---|---|---|
| Assertion ListTile | Settings crash | Material transparency |
| Horizontal scroll | Tidak nyaman di ponsel | Breakpoint 1000 px |
| Tanpa izin INTERNET | APK tidak terhubung | Manifest + cleartext lab |
| Gradle/Kotlin usang | Build gagal | Gradle 8.14.3, Kotlin 2.2.20, JDK 20 |

**Catatan:**

> “Sembilan bug nyata ditemukan, delapan diperbaiki dan diverifikasi. Build
> APK sendiri melewati tiga kegagalan toolchain sebelum berhasil.”

---

### Slide 12 — Keterbatasan

**Isi:**

- Pengujian 5 calon pengguna: **belum dilaksanakan**.
- Instalasi perangkat fisik: belum dicatat.
- Uji end-to-end dengan API key LLM: parsial.
- APK masih debug-signed.
- Backend belum dideploy.

**Catatan:**

> “Saya memilih menyampaikan ini terbuka daripada mengarang data. Tabel
> instrumen sudah siap dan akan diisi setelah sesi pengujian.”

---

### Slide 13 — Rencana & Kesimpulan

**Isi:**

- Rencana: uji pengguna, keystore rilis, CI, sinkronisasi opsional.
- Kesimpulan:
  - lima tahap selesai;
  - 12 fitur berjalan;
  - kualitas terbukti (analyzer, 16 test, APK);
  - etika terlihat di produk.

**Catatan:**

> “PayloadHub-AI menunjukkan bahwa aplikasi mobile keamanan dapat dibangun
> dengan alur yang aman, tervalidasi, dan terdokumentasi.”

---

### Slide 14 — Terima Kasih

**Isi:**

- Terima kasih.
- Repository: `github.com/farrelfaiziaulhaq/payloadhub-ai`
- Demo video: [tautan]
- Kontak: [email]

**Catatan:**

> “Saya siap menerima pertanyaan.”

---

## 3. Antisipasi Pertanyaan

| Pertanyaan | Jawaban ringkas |
|---|---|
| “Apakah ini berbahaya?” | Hanya untuk target berizin; tidak ada eksekusi otomatis; peringatan etika di produk. |
| “Kenapa riwayat tidak pakai SQLite?” | Data kecil (≤ 40 entri), butuh enkripsi at-rest; secure storage sudah tersedia tanpa dependency baru. |
| “Bagaimana jika data rusak?” | Parser defensif melewati entri invalid; JSON rusak → daftar kosong, aplikasi tetap jalan. |
| “Apakah AI selalu dipakai?” | Tidak. Generator one-liner deterministik; LLM hanya untuk penjelasan/agent. |
| “Kenapa APK 55 MB?” | Flutter engine + dependensi UI/HTTP/secure storage; masih di bawah target 60 MB. |
| “Bagaimana keamanan API key?” | Tidak ada di bundle; disimpan terenkripsi; backend memakai env. |
| “Apakah sudah diuji pengguna?” | Belum; instrumen siap, data akan diisi setelah sesi. |
| “Kenapa Gradle 8.14.3?” | Flutter 3.47 mensyaratkan ≥ 8.14; JDK 20 dipakai karena JDK 25 tidak kompatibel. |
| “Bagaimana menambah fitur?” | Buat repository/controller/provider baru; presentasi tidak perlu diubah. |
| “Apa yang terjadi tanpa backend?” | Dashboard, generator, library, riwayat, settings tetap berfungsi; fitur AI/VT menampilkan error kontekstual. |

## 4. Checklist Teknis Saat Presentasi

- [ ] Laptop terisi daya, mode presentasi aktif.
- [ ] Backend berjalan di port 8000.
- [ ] Aplikasi sudah terbuka di tab/halaman pertama.
- [ ] Video demo cadangan siap.
- [ ] Font presentasi ≥ 24 pt; kontras tinggi.
- [ ] Timer terlihat (12 menit).
- [ ] Notifikasi dimatikan.
- [ ] Tautan repository dan video dapat dibuka.

## 5. Status Verifikasi

| Klaim | Status |
|---|---|
| Jumlah slide dan alokasi waktu | **[I]** — rencana, bukan hasil |
| Data pengujian | **[C]** — sesuai output analyzer/test/build |
| Keterbatasan | **[C]** — sesuai Tahap 4/5 |
| Durasi demo 3 menit | **[I]** — perlu latihan |

**VERDICT: approve** — bahan siap; latih sekali dengan timer sebelum tampil.
