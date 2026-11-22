# Pertemuan 11: CRUD Data Mahasiswa

Tugas kelompok Mobile Programming pertemuan 11. Aplikasi Flutter memakai
SQLite (`sqflite`) untuk Create, Read, Update, dan Delete data mahasiswa.

## Berkas

| Berkas | Keterangan |
|---|---|
| `Laporan-Pertemuan-11-CRUD-Mahasiswa.docx` | Laporan Word lengkap dengan sampul dan screenshot |
| `Laporan-Pertemuan-11-CRUD-Mahasiswa.pdf` | Versi PDF untuk unggah |
| `Laporan-Pertemuan-11-CRUD-Mahasiswa.md` | Sumber laporan |
| `upload/` | Salinan Word dan PDF dengan NIM Farrel untuk unggah individu |
| `assets/screenshots/` | Screenshot E2E dari emulator |
| `assets/cover-logo.png` | Logo UIN untuk sampul |

Aplikasi ada di `crud_mahasiswa/`. APK rilis hasil build ada di
`crud_mahasiswa/build/app/outputs/flutter-apk/app-release.apk`.

## Bukti

Seluruh screenshot diambil dari aplikasi yang berjalan di emulator Android 11
(Pixel 5 API 30), bukan mockup. Skenario yang dibuktikan: kondisi kosong,
validasi form, create tiga data, pencarian, edit, NIM duplikat, dialog hapus,
hasil hapus, dan data yang tetap ada setelah aplikasi ditutup paksa.

## Verifikasi

```text
flutter analyze : No issues found
flutter test    : 6 tests passed
flutter build apk --release : berhasil (47,1 MB)
```

## Anggota

- Farrel Faiziaulhaq Azmi (240605110176)
- Naufal Ghali Rahadi (240605110161)
- Mochammad Agus Rozakhy (240605110262)
