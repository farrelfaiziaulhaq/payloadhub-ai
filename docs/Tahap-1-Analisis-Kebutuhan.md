# TAHAP 1 — Penentuan Topik dan Analisis Kebutuhan

**Mata Kuliah:** Mobile Programming
**Nama Proyek:** PayloadHub-AI
**Judul Aplikasi:** PayloadHub-AI — Asisten Cerdas Ethical Hacking Berbasis *Deterministic Tool Calling*
**Repositori:** <https://github.com/farrelfaiziaulhaq/payloadhub-ai>
**Subtema:** Keamanan Siber / *Ethical Hacking Assistant*

---

## 1. Latar Belakang dan Permasalahan

Pengujian keamanan (*penetration testing*), latihan CTF, praktikum keamanan siber, dan pekerjaan *Security Operations Center* (SOC) menuntut praktisi bergerak cepat, tetapi tetap akurat dan dapat dipertanggungjawabkan. Kenyataannya, alur kerja tersebut masih terpecah ke banyak alat dan dilakukan manual:

1. **Perakitan *reverse shell payload* manual rawan kesalahan.** Salah satu karakter, port, atau IP membuat payload gagal, dan praktisi harus mengulanginya untuk setiap kombinasi OS, bahasa, serta teknik *encoding*.
2. **Hasil pemindaian Nmap harus diterjemahkan manual ke CVE.** Praktisi mencocokkan nama layanan dan versi dengan basis data CVE di tab browser lain, sehingga waktu pencarian celah membengkak.
3. **Analisis JWT memerlukan alat tambahan.** Membaca header/payload serta mendeteksi `alg: none` atau algoritma lemah biasanya dilakukan di situs pihak ketiga yang tidak terhubung ke alur kerja.
4. **Pencarian ExploitDB dan pemeriksaan indikator ancaman tersebar.** Setiap tugas membuka aplikasi, tab, dan kredensial API yang berbeda.
5. **Asisten AI *general-purpose* berhalusinasi.** Ketika praktisi beralih ke chatbot LLM, model dapat mengarang sintaks payload, nomor CVE fiktif, atau URL yang tidak valid. Pada domain keamanan, kesalahan seperti ini berbahaya karena dapat menyesatkan saat pengujian dan menimbulkan risiko pada target.

Belum ada satu aplikasi *mobile* ringkas yang menyatukan perakitan payload tervalidasi, pemetaan CVE dari hasil scan, analisis JWT, katalog ExploitDB, dan *threat intelligence*, sekaligus **menjamin bahwa keluaran payload berasal dari library deterministik, bukan karangan model bahasa**.

## 2. Rumusan Masalah

1. Bagaimana menyatukan alur kerja pengujian keamanan berizin ke dalam satu aplikasi *mobile* yang mudah digunakan?
2. Bagaimana menghasilkan *reverse shell payload* yang konsisten dan tervalidasi tanpa mengandalkan sintaks yang ditulis bebas oleh LLM?
3. Bagaimana mempercepat pemetaan layanan/versi hasil Nmap ke referensi CVE dan katalog ExploitDB?
4. Bagaimana menyediakan analisis JWT dan *threat intelligence* dalam satu antarmuka?
5. Bagaimana menyimpan data sensitif (API key, LHOST/LPORT, riwayat) secara aman di perangkat?

## 3. Tujuan Pengembangan

1. Menyediakan aplikasi *mobile* terpadu untuk pengujian keamanan yang **berizin** (lab, CTF, aset sendiri).
2. Menghasilkan *reverse shell payload* dan *one-liner* secara **deterministik** dari library internal, bebas halusinasi sintaks.
3. Mempercepat pemetaan hasil scan Nmap ke CVE dan pencarian katalog ExploitDB.
4. Menyediakan analisis JWT instan di dalam aplikasi.
5. Menyediakan pemeriksaan *threat intelligence* (VirusTotal) untuk URL, file, hash, domain, dan IP.
6. Menyimpan API key, default LHOST/LPORT, dan riwayat aktivitas secara terenkripsi di perangkat.
7. Menerapkan kaidah Mobile Programming: navigasi antarhalaman, pengelolaan *state*, validasi masukan, pengelolaan data lokal, dan antarmuka responsif.

## 4. Identifikasi Pengguna Aplikasi

| No | Segmen pengguna | Peran | Kebutuhan utama | Tingkat keahlian |
|---:|---|---|---|---|
| 1 | *Pentester* / Security Engineer | Menjalankan uji penetrasi berizin | Payload cepat, akurat, dapat disalin; riwayat pekerjaan | Tinggi |
| 2 | Peserta CTF / Red Team Learner | Latihan eksploitasi di lab/kompetisi | Generator payload offline dan referensi exploit | Menengah |
| 3 | Mahasiswa keamanan siber | Praktikum dan belajar konsep payload, CVE, JWT | Antarmuka jelas, validasi masukan, penjelasan singkat | Rendah–menengah |
| 4 | Security Researcher | Membaca hasil scan dan mencari CVE/ExploitDB | Pencarian ExploitDB, pemetaan CVE, salin referensi | Tinggi |
| 5 | SOC Analyst / Blue Team | Memeriksa indikator ancaman | Lookup hash/URL/domain/IP ke VirusTotal | Menengah |

**Karakteristik pengguna yang menjadi dasar keputusan desain:**

- Terbiasa dengan *command line* dan terminologi keamanan, tetapi tetap membutuhkan hasil yang bisa dibaca di layar ponsel.
- Bekerja sambil berpindah perangkat; hasil harus dapat **disalin** dan **disimpan lokal**.
- Sering berada di lab dengan koneksi terbatas; fitur generator harus tetap berfungsi **offline**.
- Sadar etika: aplikasi wajib menampilkan peringatan otorisasi dan tidak boleh dipakai pada target tanpa izin.

### 4.1 Analisis Kebutuhan Pengguna (pain point → kebutuhan → fitur)

| Pain point | Kebutuhan pengguna | Fitur yang menjawab |
|---|---|---|
| Payload harus ditulis ulang tiap OS/encoding | Template payload tervalidasi, parameter LHOST/LPORT | *One-Liner Generator* deterministik |
| Hasil Nmap harus dicocokkan manual | Referensi CVE cepat | *Nmap/CVE Mapper* + *Exploit Library* |
| Analisis JWT di situs pihak ketiga | Analisis lokal/instan | *JWT Analyzer* di backend agent |
| Banyak tab dan API key tercecer | Satu pusat konfigurasi aman | *Settings* + *secure storage* |
| Hasil kerja hilang saat aplikasi ditutup | Riwayat lokal yang persisten | *Riwayat Aktivitas* (baru, Tahap 3) |
| LLM mengarang sintaks | Keluaran deterministik dan dapat diaudit | *Deterministic Tool Calling* + guardrail |

## 5. Kebutuhan Fungsional

| Kode | Kebutuhan fungsional | Prioritas | Status MVP |
|---|---|---|---|
| FR-01 | Aplikasi menampilkan *dashboard* sebagai pusat navigasi fitur. | Wajib | Selesai |
| FR-02 | Aplikasi menyediakan antarmuka agent/chat untuk menerima prompt dan konteks (target, OS, LHOST, LPORT, data scan). | Wajib | Selesai |
| FR-03 | Sistem memvalidasi masukan di layer API (regex IPv4 ketat, port 1–65535, sanitasi string) sebelum diproses. | Wajib | Selesai |
| FR-04 | Sistem menghasilkan *reverse shell payload* deterministik berdasarkan `shell_type`, `encoding`, dan argumen dari library internal. | Wajib | Selesai |
| FR-05 | Sistem memetakan layanan/versi hasil Nmap ke referensi CVE. | Wajib | Selesai |
| FR-06 | Sistem menganalisis token JWT (header/payload) dan mendeteksi `alg: none` / HS256. | Wajib | Selesai |
| FR-07 | Sistem menyediakan katalog *Exploit Library* lokal dan pencarian katalog ExploitDB resmi. | Wajib | Selesai |
| FR-08 | Sistem meneruskan permintaan *threat intelligence* ke VirusTotal (URL, file, hash, domain, IP). | Wajib | Selesai |
| FR-09 | Sistem menampilkan hasil dalam blok kode dengan *syntax highlighting* dan tombol salin. | Wajib | Selesai |
| FR-10 | Aplikasi menyimpan API key, default LHOST/LPORT secara terenkripsi di perangkat. | Wajib | Selesai |
| FR-11 | Aplikasi menyediakan halaman Monitoring dan Settings. | Wajib | Selesai |
| FR-12 | Aplikasi menangani error API (400 validasi / 500 internal) dan menampilkan pesan yang jelas. | Wajib | Selesai |
| FR-13 | Aplikasi menyimpan riwayat payload/exploit secara lokal (maks. 40 entri), dapat dilihat, disalin, dihapus, dan diekspor. | Wajib | Selesai |
| FR-14 | Aplikasi menyediakan navigasi adaptif: *sidebar* pada layar lebar dan *bottom navigation* pada ponsel. | Wajib | Selesai |
| FR-15 | Aplikasi memvalidasi LHOST/LPORT di sisi klien sebelum generator dijalankan. | Wajib | Selesai |
| FR-16 | Aplikasi menampilkan peringatan penggunaan etis dan hanya untuk target berizin. | Wajib | Selesai |

## 6. Kebutuhan Nonfungsional

| Kode | Kategori | Kebutuhan | Cara pemenuhan |
|---|---|---|---|
| NFR-01 | Keamanan | API key LLM tidak pernah dikirim ke klien; key tersimpan di server/env. | `backend/.env`, `config.py` |
| NFR-02 | Keamanan | Credential dan riwayat pengguna disimpan terenkripsi. | `flutter_secure_storage` (Android Keystore) |
| NFR-03 | Akurasi | Keluaran payload deterministik dan bebas halusinasi. | Library statis + temperature 0 |
| NFR-04 | Validasi | Validasi berlapis di API dan di setiap tool. | Pydantic + validasi tool + validator Flutter |
| NFR-05 | Performa | Respons agent ditargetkan < ±3 detik pada koneksi normal. | Batas iterasi/timeout agent |
| NFR-06 | Portabilitas | Berjalan di Android, iOS, Web, Windows, macOS, Linux. | Flutter multiplatform |
| NFR-07 | Usabilitas | Antarmuka responsif; hasil kode mudah dibaca dan disalin. | Layout adaptif, `SelectableText`, tombol salin |
| NFR-08 | Keandalan | Timeout dan batas iterasi mencegah proses menggantung. | `AGENT_TIMEOUT_SECONDS`, `AGENT_MAX_ITERATIONS` |
| NFR-09 | Skalabilitas | Backend dapat di-deploy terpisah dengan pembatasan CORS dan rate-limit. | FastAPI + `CORS_ALLOW_ORIGINS` |
| NFR-10 | Legal & etika | Hanya untuk target berizin (lab/CTF/aset sendiri). | Peringatan di UI + README |
| NFR-11 | Pemeliharaan | Kode terstruktur (*feature-first*) agar mudah dikembangkan. | `core/`, `features/`, `services/` |
| NFR-12 | Kompatibilitas | Dart SDK ≥ 3.3.0 < 4.0.0; Python ≥ 3.10. | `pubspec.yaml`, `requirements.txt` |
| NFR-13 | Aksesibilitas | Target sentuh minimal 44×44 dp; kontras teks memadai pada tema gelap. | Material 3 + `SafeArea` + ukuran tombol |

## 7. Daftar Fitur Utama

**Fitur MVP (wajib, sudah berjalan):**

1. **Dashboard adaptif** — pusat kendali, kartu tersusun vertikal di ponsel dan tiga kolom di layar lebar.
2. **Script Generator** — *One-Liner Generator* offline (bash, Python, PHP, PowerShell, web shell, privesc) dan *Custom Python Exploit Builder* berbasis agent.
3. **Agent AI backend** — orkestrasi LLM dengan *guardrail* anti-halusinasi; LLM hanya memilih dan memanggil tool.
4. **Exploit Library** — katalog lokal + pencarian katalog ExploitDB; pada ponsel detail dibuka sebagai halaman penuh.
5. **Nmap/CVE Mapper** — panel *Active Attack Surface* dan referensi CVE.
6. **JWT Analyzer** — pembacaan header/payload dan deteksi kelemahan algoritma.
7. **Threat Intelligence** — lookup URL, file, hash, domain, dan IP via VirusTotal.
8. **Monitoring** — pemantauan aktivitas/proses agent.
9. **Settings & Secure Storage** — konfigurasi API key, default LHOST/LPORT, tema.
10. **Riwayat Aktivitas** — penyimpanan lokal terenkripsi, pencarian visual, hapus per entri/semua, ekspor JSON.
11. **Info Bot** — chatbot informasional terisolasi untuk membantu pengguna memahami istilah.

**Fitur lanjutan (opsional, di luar MVP):** autentikasi multi-pengguna, sinkronisasi cloud, *workspace* tim, dan dukungan *offline* penuh untuk katalog ExploitDB.

## 8. Deskripsi Singkat Solusi

PayloadHub-AI adalah aplikasi *mobile* Flutter dengan backend FastAPI yang berfungsi sebagai asisten *ethical hacking* berbasis **Deterministic Tool Calling**. Pengguna memberikan konteks masalah (IP target, OS, data scan Nmap, atau token JWT), lalu agent AI memilih dan memanggil fungsi internal yang sudah terverifikasi untuk:

- merakit payload dari library statis internal (LLM tidak pernah menulis sintaks),
- memetakan layanan/versi hasil scan ke referensi CVE, dan
- menganalisis token JWT.

Pendekatan ini menghilangkan halusinasi pada keluaran inti karena sintaks dan data selalu berasal dari library/tool deterministik. Alur kerja dilengkapi katalog ExploitDB, *threat intelligence* VirusTotal, dan **riwayat aktivitas lokal terenkripsi** dalam satu antarmuka. Prinsip *zero knowledge on device* diterapkan: API key LLM hanya berada di server, sedangkan key pengguna, default LHOST/LPORT, dan riwayat disimpan terenkripsi melalui Android Keystore.

## 9. Ruang Lingkup dan Batasan

- Aplikasi **tidak** melakukan pemindaian jaringan secara mandiri; data Nmap dimasukkan/ditempel pengguna atau dikirim ke backend.
- Aplikasi **tidak** mengeksekusi payload ke target; aplikasi hanya menyusun dan menyalin payload.
- Backend harus dijalankan terpisah dan membutuhkan API key LLM untuk fitur agent.
- Data telemetri pada halaman Monitoring merupakan **simulasi** untuk demonstrasi antarmuka, bukan metrik host nyata.
- Pengujian pengguna terbatas pada lingkungan mahasiswa; hasilnya dilaporkan pada Tahap 4.
- Aplikasi hanya boleh digunakan pada target yang memiliki **otorisasi tertulis**.

## 10. Definisi Istilah

| Istilah | Definisi |
|---|---|
| *Reverse shell* | Koneksi yang diinisiasi target menuju penyerang sehingga penyerang memperoleh shell. |
| *Payload* | Potongan kode/perintah yang dijalankan pada target. |
| CVE | *Common Vulnerabilities and Exposures*, identitas publik untuk kerentanan. |
| JWT | *JSON Web Token*, token bertanda tangan berisi klaim pengguna. |
| *Deterministic tool calling* | Pola di mana LLM hanya memilih tool dan argumen; keluaran dihasilkan kode deterministik. |
| *Guardrail* | Aturan pembatas pada prompt/agent agar tidak menghasilkan data fiktif. |
| LHOST/LPORT | Alamat dan port pendengar (*listener*) milik penguji. |
| MVP | *Minimum Viable Product*, versi minimum yang fungsi utamanya berjalan. |

---

## 11. Status Verifikasi Dokumen

| Klaim | Status | Bukti |
|---|---|---|
| Aplikasi Flutter memiliki 5 halaman utama + riwayat | **[C]** | `frontend/lib/features/dashboard/presentation/controllers/navigation_controller.dart`, `history_screen.dart` |
| Validasi IPv4/port diterapkan | **[C]** | `frontend/lib/core/utils/validators.dart`, `backend/app/models.py` |
| Riwayat tersimpan di secure storage | **[C]** | `frontend/lib/features/history/data/activity_repository.dart` |
| Pengujian otomatis lulus | **[C]** | `flutter test` → 16 test lulus (Tahap 4) |
| Target waktu respons < 3 detik | **[S]** | Ditetapkan sebagai target NFR; belum diukur pada perangkat fisik |

**VERDICT: approve** — kebutuhan, pengguna, fitur, dan batasan sudah konsisten dengan implementasi yang ada di repositori.
