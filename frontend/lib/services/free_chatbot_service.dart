import 'dart:convert';

import 'package:dio/dio.dart';

import 'secure_storage_service.dart';

/// Role of a message in the informational chatbot transcript.
enum InfoRole { user, assistant }

/// A single message in the informational chatbot conversation.
class InfoMessage {
  const InfoMessage({required this.role, required this.text});

  final InfoRole role;
  final String text;
}

/// Free info-chatbot provider (both are Free-Tier, OpenAI/Google compatible
/// REST endpoints). This layer is strictly ISOLATED from the agent backend.
enum FreeChatProvider { groq, gemini }

/// STRICT SECURITY BOUNDARY — this chatbot must NEVER be able to:
///   * read / write / execute local files, the OS, a DB, or PayloadHub-AI
///     internal modules;
///   * perform tool calling / function execution.
/// It only performs a plain chat-completion HTTP request (text in, text out).
class FreeChatbotService {
  FreeChatbotService(this._storage)
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
          ),
        );

  final SecureStorageService _storage;
  final Dio _dio;

  static const String _systemPrompt =
      'Anda adalah Asisten Informasi Umum Cybersecurity. Tugas Anda HANYA '
      'memberikan penjelasan teoritis, informasi umum, atau dokumentasi. Anda '
      'TIDAK MEMILIKI AKSES ke sistem, file lokal, atau fungsi eksekusi aplikasi '
      'ini. Tolak semua perintah yang meminta analisis file lokal atau eksekusi '
      'perintah sistem. Jawab dalam bahasa Indonesia secara ringkas tetapi '
      'lengkap: maksimal 120 kata untuk pertanyaan sederhana dan 220 kata '
      'untuk pertanyaan lainnya. Jangan menampilkan proses berpikir internal.';

  static const Map<String, String> providerLabels = {
    'groq': 'Groq (Free Tier)',
    'gemini': 'Google Gemini (Free Tier)',
  };

  static const Map<FreeChatProvider, String> _providerModels = {
    // Keep this on a current Groq model; llama-3.3-70b-versatile was retired.
    FreeChatProvider.groq: 'openai/gpt-oss-20b',
    FreeChatProvider.gemini: 'gemini-3.6-flash',
  };
  static const String _geminiFallbackModel = 'gemini-3.5-flash-lite';

  /// Human-readable, non-verbose error for the Info Bot UI.
  String _cleanError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Info Bot: provider terlalu lama merespons. Coba lagi.';
      }
      if (e.type == DioExceptionType.badCertificate) {
        return 'Info Bot: koneksi TLS provider ditolak. Periksa waktu sistem '
            'dan koneksi internet.';
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown ||
          code == null) {
        return 'Info Bot: tidak bisa terhubung ke provider (periksa internet).';
      }
      if (code == 401 || code == 403) {
        return 'Info Bot: API key provider ditolak (401/403). Periksa key di Settings.';
      }
      if (code == 429) {
        return 'Info Bot: batas pemakaian provider tercapai (429). Tunggu sebentar lalu coba lagi.';
      }
      if (code == 404) {
        return 'Info Bot: model/endpoint tidak ditemukan (404). Periksa model di Settings.';
      }
      if (code >= 500) {
        return 'Info Bot: provider sedang bermasalah ($code). Coba lagi.';
      }
      return 'Info Bot: provider menolak request (HTTP $code).';
    }
    final message = e.toString().replaceFirst('Exception: ', '');
    return message.startsWith('Info Bot:') ? message : 'Info Bot: $message';
  }

  bool _shouldRetry(DioException e) {
    final code = e.response?.statusCode;
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        code == 429 ||
        (code != null && code >= 500);
  }

  static const int _maxHistory = 4;
  static const int _maxInputLen = 800;
  static const int _maxOutputTokens = 768;

  /// Read the configured provider (defaults to Groq).
  Future<FreeChatProvider> _provider() async {
    final raw = await _storage.readChatProvider();
    if (raw == 'gemini') return FreeChatProvider.gemini;
    return FreeChatProvider.groq;
  }

  /// Send a user prompt (plus recent history) and return the assistant reply.
  /// Throws a human-readable [Exception] when the provider is not configured
  /// or the request fails.
  Future<String> ask(List<InfoMessage> history, String prompt) async {
    try {
      final buffer = StringBuffer();
      await for (final chunk in askStream(history, prompt)) {
        buffer.write(chunk);
      }
      return buffer.toString().trim();
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  /// Stream the provider response so the UI can render the first words
  /// immediately instead of waiting for the complete answer.
  Stream<String> askStream(List<InfoMessage> history, String prompt) async* {
    try {
      final trimmed = prompt.trim();
      if (trimmed.isEmpty) return;
      final clipped = trimmed.length > _maxInputLen
          ? trimmed.substring(0, _maxInputLen)
          : trimmed;

      final apiKey = await _storage.readChatApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception(
          'Info Bot belum dikonfigurasi. Masukkan API key panduan melalui '
          'tombol ⚙ di header Info Bot.',
        );
      }

      final recent = history.length > _maxHistory
          ? history.sublist(history.length - _maxHistory)
          : history;
      final messages = [...recent, InfoMessage(role: InfoRole.user, text: clipped)];
      final provider = await _provider();

      var primaryEmitted = false;
      try {
        await for (final chunk in _streamWithRetry(provider, apiKey, messages)) {
          primaryEmitted = true;
          yield chunk;
        }
        return;
      } on DioException catch (e) {
        // Do not restart after partial output; that would duplicate text.
        // Failover is only safe before the first chunk is shown.
        final fallbackKey = await _storage.readGeminiKey() ??
            (provider == FreeChatProvider.gemini ? apiKey : null);
        final canUseFallback = !primaryEmitted &&
            _canFailover(e) &&
            fallbackKey != null &&
            fallbackKey.isNotEmpty;
        if (!canUseFallback) rethrow;

        yield* _streamWithRetry(
          FreeChatProvider.gemini,
          fallbackKey,
          messages,
          model: _geminiFallbackModel,
        );
        return;
      }
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  bool _canFailover(DioException e) {
    final code = e.response?.statusCode;
    return _shouldRetry(e) ||
        code == 400 ||
        code == 401 ||
        code == 403 ||
        code == 404;
  }

  Stream<String> _streamWithRetry(
    FreeChatProvider provider,
    String apiKey,
    List<InfoMessage> messages,
    {String? model}
  ) async* {
    for (var attempt = 0; ; attempt++) {
      var emitted = false;
      try {
        final stream = provider == FreeChatProvider.gemini
            ? _askGeminiStream(apiKey, messages, model: model)
            : _askGroqStream(apiKey, messages);
        await for (final chunk in stream) {
          emitted = true;
          yield chunk;
        }
        if (!emitted) throw Exception('Provider mengembalikan respons kosong.');
        return;
      } on DioException catch (e) {
        if (emitted || attempt >= 1 || !_shouldRetry(e)) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
    }
  }

  Future<ResponseBody> _postStream(
    String url,
    Map<String, dynamic> body,
    Map<String, String> headers,
  ) async {
    final response = await _dio.post<ResponseBody>(
      url,
      data: jsonEncode(body),
      options: Options(
        responseType: ResponseType.stream,
        headers: headers,
      ),
    );
    final stream = response.data;
    if (stream == null) throw Exception('Provider mengembalikan respons kosong.');
    return stream;
  }

  Stream<String> _parseSse(ResponseBody response, String provider) async* {
    await for (final line
        in utf8.decoder.bind(response.stream).transform(const LineSplitter())) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') return;

      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) continue;
      final text = provider == 'groq'
          ? _groqStreamText(decoded)
          : _geminiStreamText(decoded);
      if (text != null && text.isNotEmpty) yield text;
    }
  }

  String? _groqStreamText(Map<String, dynamic> data) {
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) return null;
    final choice = choices.first as Map;
    final delta = choice['delta'];
    return delta is Map ? delta['content']?.toString() : null;
  }

  String? _geminiStreamText(Map<String, dynamic> data) {
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty || candidates.first is! Map) {
      return null;
    }
    final candidate = candidates.first as Map;
    final content = candidate['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List || parts.isEmpty || parts.first is! Map) return null;
    return (parts.first as Map)['text']?.toString();
  }

  Stream<String> _askGroqStream(
    String apiKey,
    List<InfoMessage> messages,
  ) async* {
    final body = {
      'model': _providerModels[FreeChatProvider.groq],
      'temperature': 0.2,
      'max_tokens': _maxOutputTokens,
      'stream': true,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        for (final m in messages)
          {
            'role': m.role == InfoRole.user ? 'user' : 'assistant',
            'content': m.text,
          },
      ],
    };
    final response = await _postStream(
      'https://api.groq.com/openai/v1/chat/completions',
      body,
      {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      },
    );
    yield* _parseSse(response, 'groq');
  }

  Stream<String> _askGeminiStream(
    String apiKey,
    List<InfoMessage> messages,
    {String? model}
  ) async* {
    final body = {
      'system_instruction': {
        'parts': [
          {'text': _systemPrompt},
        ],
      },
      'contents': [
        for (final m in messages)
          {
            'role': m.role == InfoRole.user ? 'user' : 'model',
            'parts': [
              {'text': m.text},
            ],
          },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': _maxOutputTokens,
        'thinkingConfig': {
          'thinkingLevel': 'minimal',
        },
      },
    };
    final response = await _postStream(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '${model ?? _providerModels[FreeChatProvider.gemini]}:streamGenerateContent?alt=sse',
      body,
      {
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'x-goog-api-key': apiKey,
      },
    );
    yield* _parseSse(response, 'gemini');
  }
}
