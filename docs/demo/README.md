# Video demonstrasi singkat

**Video utama Android:** `PayloadHub-AI-Demo-Android.mp4`.

Sumbernya APK asli di emulator Pixel 5 API 30 x64, direkam dengan
`adb screenrecord`. Berisi generator dengan input lab, hasil payload,
riwayat dan detail, katalog exploit, serta pertanyaan dan jawaban DeepSeek
langsung di Info Bot. Tidak ada key yang ditampilkan.

Video disusun dari dua rekaman asli. Jeda diam antar langkah dipangkas;
kecepatan interaksi dan waktu tunggu respons tidak dipercepat. Subtitle
Indonesia ditempatkan di luar area layar Android. Tidak ada narasi suara.
Resolusi keluaran 900 × 1800, durasi **1 menit 44 detik**.

> Emulator pada mesin ini menangkap sekitar 2 fps saat `screenrecord`.
> Gerakan UI karena itu tidak mulus, tetapi setiap frame berasal dari APK
> yang benar-benar berjalan; tidak ada frame animasi buatan.

Versi browser: `PayloadHub-AI-Demo.mp4`.

Rekaman interaksi langsung aplikasi Flutter dengan tampilan HP potret
390 × 844, diekspor ke MP4 1080 × 1920. Rekaman bukan slideshow screenshot
dan tidak menggunakan mockup. Teks penjelas Indonesia ditempatkan di luar
area aplikasi; video tidak memiliki narasi suara.

## Alur

1. Beranda mobile dan alat cepat.
2. Generator: validasi input kosong.
3. Pengisian LHOST/LPORT lab dan pembuatan payload.
4. Riwayat yang terbentuk dari aktivitas tersebut dan detailnya.
5. Daftar dan detail exploit bawaan; PoC tidak dijalankan.
6. Setelan dan peringatan penggunaan berizin.

## Batas verifikasi

**Keterangan ini hanya berlaku untuk versi browser:** rekaman berasal dari
build web Flutter di Chrome dengan viewport HP,
**bukan rekaman emulator atau perangkat Android fisik**. Ini membuktikan
interaksi UI mobile yang direkam, bukan kompatibilitas instalasi Android
atau keberhasilan backend AI. Katalog exploit adalah data bawaan aplikasi.

## Pemeriksaan API lokal (29 Oktober 2026)

- DeepSeek: endpoint model dan satu chat completion mengembalikan HTTP 200.
- Shodan: endpoint informasi akun mengembalikan HTTP 200; ini bukan bukti
  integrasi Shodan di antarmuka aplikasi.
- VirusTotal: pemeriksaan akun dan lookup `example.com` melalui backend
  mengembalikan HTTP 200.
- FastAPI `/healthz` dan permintaan penjelasan LHOST/LPORT melalui agent
  mengembalikan HTTP 200.

Credential disimpan di `backend/.env` yang diabaikan Git. Tidak ada nilai
key di dokumentasi atau video. Video browser awal tidak menampilkan AI;
hasil pemeriksaan API di atas merupakan pengujian terpisah.

## Verifikasi Android

APK terbaru berhasil dipasang dan dibuka di emulator Pixel 5 API 30 x64.
Info Bot telah menjawab pertanyaan LHOST/LPORT lewat DeepSeek langsung
dari aplikasi Android. Key dimasukkan ke Settings sebelum merekam dan
disimpan oleh `flutter_secure_storage`. Generator dinamis menggunakan
backend lokal dengan DeepSeek; generator one-liner tetap deterministik.

Script `docs/tools/android_demo.py` merekam APK menggunakan `adb screenrecord`.
Hasilnya dipisahkan dari video browser agar sumber rekaman tidak tertukar.
Pencarian beberapa elemen otomatis tidak stabil pada emulator ini, sehingga
rekaman akhir dilanjutkan dengan tap berdasarkan screenshot aktual.
`assemble_android_demo.py` menggabungkan dua rekaman asli sesuai segmen yang
dicatat di `android-recording.json`. Video tidak menampilkan integrasi
Shodan/VirusTotal atau generator dinamis backend; hasil tes API tersebut
merupakan pengujian terpisah, bukan adegan video.

## Berkas

- `PayloadHub-AI-Demo-Android.mp4` — video utama dari emulator Android.
- `PayloadHub-AI-Demo.mp4` — alternatif browser, viewport HP.
- `cover.jpg` — bingkai jawaban DeepSeek untuk thumbnail.
- `android-recording.json` — sumber segmen, resolusi, dan batas verifikasi.
- `raw/` — dua rekaman `adb screenrecord` sebelum penggabungan.

Build APK demo terbaru menggunakan `--target-platform android-x64` untuk
emulator. APK ini tidak menggantikan paket universal rilis untuk HP ARM.
Analyzer lulus dan `flutter test --concurrency=1` melaporkan 16 test lulus.

## Reproduksi

Setelah membangun web di folder `frontend` dengan `flutter build web --release`,
jalankan dari root repository:

```powershell
python docs/tools/record_demo.py
```

Memerlukan Python, Playwright, Chrome, Pillow, dan imageio-ffmpeg.
`recording.json` mencatat sumber, ukuran, durasi, dan urutan interaksi;
`PayloadHub-AI-Demo.srt` berisi subtitle. Rekaman WebM asli disimpan di
subfolder `raw/`.
