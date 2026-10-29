# Dokumentasi PayloadHub-AI

Indeks seluruh dokumen proyek akhir. Mulai dari laporan tahapan, lalu gunakan
dokumen teknis dan panduan presentasi sesuai kebutuhan.

## Urutan membaca

| Urutan | Dokumen | Untuk siapa | Isi |
|---:|---|---|---|
| 0 | [Laporan Lengkap (gabungan)](PayloadHub-AI-Laporan-Lengkap.md) | Dosen, pengumpulan | **Satu dokumen utuh** ringkasan Tahap 1–5 + teknis + demo |
| 1 | [Tahap 1 — Analisis Kebutuhan](Tahap-1-Analisis-Kebutuhan.md) | Dosen, penguji | Latar belakang, persona, kebutuhan, etika, prioritas |
| 2 | [Tahap 2 — Perancangan Sistem](Tahap-2-Perancangan-Sistem.md) | Dosen, penguji | Arsitektur, navigasi, design system, wireframe |
| 3 | [Tahap 3 — Implementasi](Tahap-3-Implementasi.md) | Pengembang | Struktur kode, fitur, keputusan teknis |
| 4 | [Tahap 4 — Pengujian](Tahap-4-Pengujian.md) | Penguji | 24 kasus fungsional, 7 nonfungsional, 9 bug, instrumen uji pengguna |
| 5 | [Tahap 5 — Laporan Akhir](Tahap-5-Laporan-Akhir.md) | Semua | Ringkasan hasil, artefak rilis, rubrik, keterbatasan |
| — | [Dokumentasi Teknis](DOKUMENTASI-TEKNIS.md) | Pengembang | Setup, build, API, storage, troubleshooting |
| — | [Panduan Demo Video](PANDUAN-DEMO-VIDEO.md) | Presenter | Naskah 8–10 menit dan checklist rekaman |
| — | [Video Demo Android](demo/PayloadHub-AI-Demo-Android.mp4) | Presenter, dosen | Rekaman APK asli di emulator, 1 menit 44 detik |
| — | [Bahan Presentasi](BAHAN-PRESENTASI.md) | Presenter | 14 slide, catatan pembicara, Q&A |

## Aset desain

| Aset | Lokasi | Keterangan |
|---|---|---|
| Wireframe dashboard | [`assets/wireframe-dashboard.svg`](assets/wireframe-dashboard.svg) | Layout desktop dan mobile |
| Wireframe generator | [`assets/wireframe-generator.svg`](assets/wireframe-generator.svg) | Form, validasi, hasil |
| Wireframe exploit | [`assets/wireframe-exploit.svg`](assets/wireframe-exploit.svg) | Daftar dan detail |
| Wireframe riwayat | [`assets/wireframe-history.svg`](assets/wireframe-history.svg) | Daftar, detail, ekspor |
| Wireframe settings | [`assets/wireframe-settings.svg`](assets/wireframe-settings.svg) | Key, preferensi, About |
| Purwarupa interaktif | [`prototipe/index.html`](prototipe/index.html) | Buka di browser, tanpa server |
| Screenshot mobile | [`assets/screenshots/`](assets/screenshots) | 8 tampilan nyata pada viewport 390×844 |
| Generator wireframe | [`tools/gen_wireframes.py`](tools/gen_wireframes.py) | Regenerasi semua SVG |
| Konversi DOCX | [`tools/md_to_docx.py`](tools/md_to_docx.py) | Regenerasi laporan Word |

## Versi DOCX

Salinan Word dari seluruh laporan tersedia di [`docx/`](docx). Hasilkan ulang
setelah mengubah Markdown:

```bash
python docs/tools/md_to_docx.py
```

## Hasil verifikasi terkini

```text
flutter analyze  → No issues found!
flutter test     → 16 tests passed
APK rilis        → 55,5 MB (58.156.477 byte)
```

Detail dan tanggal build ada di [Tahap 5 §4](Tahap-5-Laporan-Akhir.md#4-artefak-rilis).

## Catatan integritas

- Data pengujian pengguna **belum ada**; tabel di Tahap 4 sengaja kosong.
- Instalasi pada perangkat fisik belum dicatat.
- Klaim pada dokumen ditandai `[C]` (terverifikasi), `[I]` (inferensi), atau
  `[S]` (belum terverifikasi) bila relevan.

## Konvensi berkas

- Nama berkas tahap: `Tahap-<n>-<Topik>.md`.
- Bahasa: Indonesia; istilah teknis dipertahankan.
- Diagram: Mermaid di Markdown, SVG untuk wireframe.
- Tanggal: format `23 Oktober 2026`.
