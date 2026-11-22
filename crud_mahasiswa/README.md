# CRUD Mahasiswa

Aplikasi Flutter untuk praktikum Pemrograman Mobile pertemuan 11. Aplikasi
mengelola data mahasiswa secara lokal memakai SQLite (`sqflite`) dengan alur
Create, Read, Update, dan Delete.

## Fitur

- Tambah data dengan validasi NIM 8 sampai 15 digit, nama, dan program studi.
- Daftar data dengan pencarian nama, NIM, atau program studi.
- Ubah data melalui form yang sama.
- Hapus data dengan dialog konfirmasi.
- NIM unik, duplikat ditolak database dan ditampilkan sebagai pesan yang jelas.
- Data tetap ada setelah aplikasi ditutup karena disimpan di SQLite perangkat.
- Status kosong, loading, error, dan hasil pencarian kosong.
- Ringkasan jumlah mahasiswa dan program studi dari data nyata.

## Menjalankan

SQLite tidak berjalan di Chrome atau Windows tanpa plugin tambahan, jadi
jalankan di emulator Android atau HP:

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
```

Pada emulator, jika perangkat belum aktif, jalankan emulator dari Android
Studio terlebih dahulu.

## Struktur

```text
lib/
├── main.dart
├── database/database_helper.dart
├── models/mahasiswa.dart
├── screens/mahasiswa_form_page.dart
├── screens/mahasiswa_list_page.dart
├── theme/app_theme.dart
└── utils/validators.dart
```

Skema database:

```sql
CREATE TABLE mahasiswa (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nim TEXT NOT NULL UNIQUE,
  nama TEXT NOT NULL,
  prodi TEXT NOT NULL
);
```

## Pengujian

```bash
flutter analyze
flutter test
```

Bukti E2E dan laporan ada di `docs/pertemuan-11/`.
