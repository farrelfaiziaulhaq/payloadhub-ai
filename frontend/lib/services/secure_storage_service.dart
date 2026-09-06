import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Singleton wrapper around [FlutterSecureStorage].
///
/// STRICT RULE #4 — every sensitive value (LLM API key, default LHOST/LPORT)
/// is encrypted at rest via Android Keystore (EncryptedSharedPreferences).
/// Nothing sensitive is ever written to plaintext SharedPreferences.
class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kApiKey = 'llm_api_key';
  static const _kDefaultLhost = 'default_lhost';
  static const _kDefaultLport = 'default_lport';
  static const _kBaseUrl = 'backend_base_url';
  static const _kChatProvider = 'free_chat_provider';
  static const _kChatApiKey = 'free_chat_api_key';
  // Settings page keys. External provider keys are entered by the user and
  // stored encrypted; no provider key is shipped in the application bundle.
  static const _kOpenAiKey = 'api_openai';
  static const _kDeepSeekKey = 'api_deepseek';
  static const _kGeminiKey = 'api_gemini';
  static const _kShodanKey = 'api_shodan';
  static const _kVirusTotalKey = 'api_virustotal';
  static const _kLlmEngine = 'llm_engine';
  static const _kTglow = 'ui_glow';
  static const _kTerminalFont = 'ui_terminal_font';
  static const _kSound = 'ui_sound';

  // ---- API key -----------------------------------------------------------
  Future<void> writeApiKey(String value) =>
      _storage.write(key: _kApiKey, value: value);

  Future<String?> readApiKey() => _storage.read(key: _kApiKey);

  Future<void> deleteApiKey() => _storage.delete(key: _kApiKey);

  // ---- Default LHOST -----------------------------------------------------
  Future<void> writeDefaultLhost(String value) =>
      _storage.write(key: _kDefaultLhost, value: value);

  Future<String?> readDefaultLhost() => _storage.read(key: _kDefaultLhost);

  // ---- Default LPORT -----------------------------------------------------
  Future<void> writeDefaultLport(int value) =>
      _storage.write(key: _kDefaultLport, value: value.toString());

  Future<int?> readDefaultLport() async {
    final raw = await _storage.read(key: _kDefaultLport);
    return raw == null ? null : int.tryParse(raw);
  }

  // ---- Backend base URL --------------------------------------------------
  Future<void> writeBaseUrl(String value) =>
      _storage.write(key: _kBaseUrl, value: value);

  Future<String?> readBaseUrl() => _storage.read(key: _kBaseUrl);

  // ---- Free informational chatbot (provider + API key) -------------------
  Future<void> writeChatProvider(String value) =>
      _storage.write(key: _kChatProvider, value: value);

  Future<String?> readChatProvider() => _storage.read(key: _kChatProvider);

  Future<void> writeChatApiKey(String value) =>
      _storage.write(key: _kChatApiKey, value: value);

  Future<String?> readChatApiKey() => _storage.read(key: _kChatApiKey);

  // ---- Settings: external API keys ---------------------------------------
  Future<void> writeOpenAiKey(String value) =>
      _storage.write(key: _kOpenAiKey, value: value);

  Future<String?> readOpenAiKey() => _storage.read(key: _kOpenAiKey);

  Future<void> writeDeepSeekKey(String value) =>
      _storage.write(key: _kDeepSeekKey, value: value);

  Future<String?> readDeepSeekKey() => _storage.read(key: _kDeepSeekKey);

  Future<void> writeGeminiKey(String value) =>
      _storage.write(key: _kGeminiKey, value: value);

  Future<String?> readGeminiKey() => _storage.read(key: _kGeminiKey);

  Future<void> writeShodanKey(String value) =>
      _storage.write(key: _kShodanKey, value: value);

  Future<String?> readShodanKey() => _storage.read(key: _kShodanKey);

  Future<void> writeVirusTotalKey(String value) =>
      _storage.write(key: _kVirusTotalKey, value: value);

  Future<String?> readVirusTotalKey() => _storage.read(key: _kVirusTotalKey);

  // ---- Settings: LLM engine + UI toggles ---------------------------------
  Future<void> writeLlmEngine(String value) =>
      _storage.write(key: _kLlmEngine, value: value);

  Future<String?> readLlmEngine() => _storage.read(key: _kLlmEngine);

  Future<void> writeUiGlow(bool value) =>
      _storage.write(key: _kTglow, value: value.toString());

  Future<bool> readUiGlow() async =>
      (await _storage.read(key: _kTglow)) == 'true';

  Future<void> writeTerminalFont(bool value) =>
      _storage.write(key: _kTerminalFont, value: value.toString());

  Future<bool> readTerminalFont() async =>
      (await _storage.read(key: _kTerminalFont)) == 'true';

  Future<void> writeSound(bool value) =>
      _storage.write(key: _kSound, value: value.toString());

  Future<bool> readSound() async =>
      (await _storage.read(key: _kSound)) == 'true';

  // ---- Wipe all ----------------------------------------------------------
  Future<void> clearAll() => _storage.deleteAll();
}
