# Script bantuan

Semua perintah dijalankan dari **root repository**.

| Perintah | Fungsi |
|---|---|
| `python scripts/payloadhub.py setup` | Buat venv, pasang dependency Python, salin `.env.example`, `flutter pub get` |
| `python scripts/payloadhub.py backend` | Jalankan FastAPI di `0.0.0.0:8000` |
| `python scripts/payloadhub.py desktop` | Jalankan Flutter desktop sesuai OS |
| `python scripts/payloadhub.py android` | Pilih perangkat Android lalu `flutter run` |
| `python scripts/payloadhub.py apk` | Build APK rilis |
| `python scripts/payloadhub.py doctor` | Tampilkan status Python/Flutter/venv |

Windows PowerShell juga bisa memakai `.\setup.ps1`; Linux/macOS memakai
`./setup.sh`.

Script ini tidak pernah menulis API key. Key backend tetap di `backend/.env`
yang diabaikan Git.
