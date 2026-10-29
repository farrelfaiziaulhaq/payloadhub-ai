# Panduan Demo Video — PayloadHub-AI

> **Video jadi:** [`demo/PayloadHub-AI-Demo-Android.mp4`](demo/PayloadHub-AI-Demo-Android.mp4)
> — rekaman APK asli di emulator Android, 1 menit 44 detik.

**Durasi target:** 8–10 menit
**Rasio:** 16:9, 1080p, 30 fps
**Bahasa:** Indonesia
**Tujuan:** menunjukkan aplikasi berjalan, fitur utama, alur pengguna, dan
kualitas teknis tanpa melebih-lebihkan hasil.

---

## 1. Daftar Periksa Sebelum Merekam

### 1.1 Lingkungan

- [ ] Backend berjalan: `uvicorn app.main:app --reload --host 0.0.0.0 --port 8000`.
- [ ] `curl http://127.0.0.1:8000/healthz` mengembalikan `{"status":"ok"}`.
- [ ] `LLM_API_KEY` terisi bila ingin mendemokan fitur agent. Jika tidak,
      gunakan mode deterministik dan jelaskan dengan jujur.
- [ ] `VIRUSTOTAL_API_KEY` terisi bila ingin mendemokan Threat Intelligence.
- [ ] Emulator/perangkat menampilkan aplikasi versi rilis.
- [ ] APK terpasang: `adb install -r frontend/build/app/outputs/flutter-apk/app-release.apk`.
- [ ] Mode jangan ganggu aktif; notifikasi dimatikan.
- [ ] Wallpaper netral, ikon desktop dirapikan.
- [ ] Zoom terminal 125–150% agar teks terbaca.

### 1.2 Data demo

Siapkan nilai berikut agar alur konsisten:

| Field | Nilai |
|---|---|
| LHOST | `10.10.14.8` |
| LPORT | `9001` |
| Pencarian exploit | `CVE-2021-42013` |
| Target monitoring | `lab.local` |

### 1.3 Cadangan

- Rekaman layar alternatif bila emulator lambat.
- Tangkapan layar dashboard, generator, dan riwayat sebagai *cutaway*.
- Jika backend gagal, tunjukkan generator deterministik dan riwayat; jelaskan
  bahwa fitur AI memerlukan backend.

## 2. Struktur Video

| Waktu | Segmen | Isi |
|---|---|---|
| 0:00–0:30 | Pembuka | Judul, nama, tujuan |
| 0:30–1:30 | Masalah & solusi | Persona, pain point, fitur |
| 1:30–2:30 | Arsitektur | Flutter + FastAPI, data flow |
| 2:30–5:30 | Demo utama | Dashboard, generator, riwayat |
| 5:30–7:00 | Fitur pendukung | Exploit Library, Settings, About |
| 7:00–8:00 | Kualitas | Analyze, test, APK |
| 8:00–9:00 | Penutup | Keterbatasan, rencana, terima kasih |

## 3. Naskah per Segmen

### 3.1 Pembuka (0:00–0:30)

**Visual:** slide judul atau dashboard dalam keadaan idle.

**Narasi:**

> “Halo, saya Farrel Faizi Aulhaq. Video ini mendemonstrasikan PayloadHub-AI,
> aplikasi ethical hacking assistant berbasis Flutter yang saya kembangkan
> untuk proyek akhir Pemrograman Mobile. Aplikasi ini membantu menyiapkan
> bahan pengujian keamanan pada sistem yang memiliki izin, dan menekankan
> validasi serta etika penggunaan.”

### 3.2 Masalah dan solusi (0:30–1:30)

**Visual:** slide ringkas 3 pain point → 3 solusi.

**Narasi:**

> “Praktisi pemula sering menulis payload berulang, lupa konfigurasi listener,
> dan kehilangan catatan sesi. PayloadHub-AI menjawabnya dengan generator
> tervalidasi, prefill konfigurasi dari Settings, dan riwayat aktivitas
> terenkripsi. Semua fitur dirancang untuk mobile: navigasi bawah, layout
> satu kolom, dan target sentuh yang nyaman.”

**Poin yang harus muncul:**

- generator deterministik;
- validasi IPv4/port;
- riwayat lokal terenkripsi;
- peringatan otorisasi.

### 3.3 Arsitektur (1:30–2:30)

**Visual:** diagram arsitektur (bisa dari `DOKUMENTASI-TEKNIS.md` §1).

**Narasi:**

> “Klien Flutter menggunakan Riverpod untuk state, Dio untuk HTTP, dan
> flutter_secure_storage untuk data sensitif. Backend FastAPI memvalidasi
> ulang input, menjalankan agent dengan guardrail, dan menyediakan pencarian
> ExploitDB serta VirusTotal. Generator one-liner tetap berjalan tanpa
> backend, sehingga aplikasi tidak lumpuh saat jaringan bermasalah.”

### 3.4 Demo dashboard (2:30–3:15)

**Langkah:**

1. Buka aplikasi dari home screen.
2. Tunjukkan dashboard pada orientasi potret.
3. Gulir perlahan; tunjukkan kartu Studio, Riwayat, Payload Library.
4. Putar perangkat ke lanskap atau buka jendela desktop untuk menunjukkan
   layout tiga kolom (opsional, jika merekam desktop).
5. Tekan setiap item bottom navigation sekali.

**Narasi:**

> “Di ponsel, dashboard tersusun satu kolom dan navigasi berada di bawah dalam
> SafeArea. Di layar lebar, sidebar dan tiga kolom aktif. Tidak ada scroll
> horizontal.”

### 3.5 Demo generator (3:15–4:30)

**Langkah:**

1. Buka **Script Generator**.
2. Tekan **Generate** dengan field kosong → tunjukkan pesan
   `IP address is required` dan `Port is required`.
3. Isi `999.1.1.1` → tunjukkan `Enter a valid IPv4 address`.
4. Isi `10.10.14.8` dan `9001`.
5. Pilih tipe payload (bash), tekan **Generate**.
6. Tunjukkan kode hasil, tombol salin, dan SnackBar.
7. Kembali ke Dashboard → panel Riwayat menunjukkan entri baru.

**Narasi:**

> “Validasi terjadi sebelum payload dibuat. Setelah berhasil, hasil disalin
> dengan satu ketukan dan otomatis masuk ke riwayat. Tidak ada panggilan LLM
> pada alur ini, sehingga hasilnya konsisten dan dapat diulang.”

### 3.6 Demo riwayat (4:30–5:30)

**Langkah:**

1. Buka **Riwayat Aktivitas** dari top bar atau sidebar.
2. Tunjukkan entri, waktu, dan jenis.
3. Ketuk entri → detail kode.
4. Salin dari detail.
5. Gunakan pencarian (bila tersedia) untuk memfilter.
6. Geser/hapus satu entri → tunjukkan konfirmasi.
7. Tekan ekspor → tunjukkan SnackBar dan tempel JSON di editor teks.
8. Tutup aplikasi sepenuhnya, buka lagi, buka riwayat → entri tetap ada.

**Narasi:**

> “Riwayat disimpan di secure storage, bukan preferensi biasa, karena isinya
> dapat berisi payload sensitif. Maksimal empat puluh entri, yang tertua
> dibuang otomatis. Data yang rusak diabaikan agar aplikasi tetap dapat
> dibuka.”

### 3.7 Demo fitur pendukung (5:30–7:00)

**Exploit Library:**

1. Buka **Exploit Library**.
2. Cari `CVE-2021-42013`.
3. Buka detail → tunjukkan halaman penuh di ponsel.
4. Tekan **Send to Studio** → kembali ke dashboard dengan konfigurasi terisi.

**Settings:**

1. Buka **Settings**.
2. Tunjukkan field API key tersamarkan.
3. Isi LHOST/LPORT, tekan **Save**.
4. Buka generator → tunjukkan prefill.

**About:**

1. Buka dialog About dari top bar.
2. Tunjukkan peringatan etika dan versi.

**Narasi:**

> “Pengaturan disimpan aman dan langsung dipakai generator. Detail exploit
> memakai rute penuh di ponsel agar kode mudah dibaca.”

### 3.8 Kualitas teknis (7:00–8:00)

**Visual:** terminal.

```powershell
cd frontend
flutter analyze
flutter test
Get-Item build\app\outputs\flutter-apk\app-release.apk |
  Select-Object Name, Length, LastWriteTime
```

**Narasi:**

> “Analyzer bersih dan enam belas pengujian otomatis lulus, mencakup validasi,
> serialisasi riwayat, kegagalan penyimpanan, serta layout desktop dan ponsel.
> APK rilis berukuran lima puluh lima koma dua megabita dan berhasil dibangun
> dengan Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20, dan JDK 20.”

### 3.9 Penutup (8:00–9:00)

**Narasi:**

> “Keterbatasan yang masih terbuka adalah pengujian dengan calon pengguna dan
> verifikasi pada perangkat fisik, yang akan saya lakukan sebelum presentasi.
> Rencana berikutnya adalah keystore rilis, CI build, dan sinkronisasi riwayat
> opsional. Terima kasih.”

## 4. Rekaman Layar

### 4.1 Opsi A — Android (disarankan)

```powershell
# Rekam 3 menit
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb shell screenrecord --time-limit 180 --bit-rate 8000000 /sdcard/demo.mp4
& $adb pull /sdcard/demo.mp4 .\demo-android.mp4
```

Batasan `screenrecord`: maksimal 3 menit per berkas dan tanpa audio internal.
Rekam audio secara terpisah, lalu gabungkan di editor.

### 4.2 Opsi B — Desktop

- Windows: `Win + G` (Xbox Game Bar) atau OBS Studio.
- Atur sumber ke jendela aplikasi, resolusi 1920×1080.
- Rekam mikrofon pada track terpisah.

### 4.3 Opsi C — Web

```powershell
flutter run -d chrome
```

Gunakan OBS dengan sumber *Window Capture*; hindari *Browser Source* agar
animasi tetap halus.

## 5. Pengeditan

| Langkah | Detail |
|---|---|
| Potong | Buang jeda > 2 detik dan muat ulang yang tidak perlu |
| Zoom | Perbesar area form/riwayat saat kode ditampilkan |
| Callout | Beri label “validasi”, “riwayat terenkripsi”, “layout satu kolom” |
| Subtitle | Bahasa Indonesia, ukuran 24–28 px, kontras tinggi |
| Musik | Instrumental volume rendah (−25 dB), bebas royalti |
| Intro/outro | 3–5 detik, tidak berlebihan |
| Export | MP4 H.264, 1080p, 8–10 Mbps |

## 6. Kesalahan yang Harus Dihindari

- Menampilkan API key asli di layar.
- Mengklaim “sudah diuji 5 pengguna” tanpa data.
- Mempercepat video saat pesan error ditampilkan.
- Menampilkan payload ke target publik.
- Musik terlalu keras hingga narasi tidak jelas.
- Durasi melebihi 12 menit tanpa alasan.

## 7. Daftar Periksa Setelah Merekam

- [ ] Tidak ada key, token, atau email pribadi yang terlihat.
- [ ] Semua langkah berhasil atau kegagalan dijelaskan.
- [ ] Audio konsisten, tidak clipping.
- [ ] Teks terminal terbaca pada 1080p.
- [ ] Durasi 8–10 menit.
- [ ] File dinamai `PayloadHub-AI_Demo_Farrel.mp4`.
- [ ] Unggah ke Google Drive/YouTube unlisted; cantumkan tautan di laporan.

## 8. Status Verifikasi

| Klaim | Status |
|---|---|
| Urutan demo sesuai fitur yang ada | **[C]** — dicek pada kode dan widget test |
| Perintah rekam Android | **[C]** — `adb screenrecord` |
| Hasil rekaman | **[S]** — belum direkam saat dokumen disusun |

**VERDICT: approve** — naskah siap dipakai; hasil rekaman wajib diverifikasi
sendiri sebelum diserahkan.
