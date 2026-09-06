import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/secure_storage_service.dart';
import '../../../payload_chat/domain/entities/chat_message.dart';
import '../../../payload_chat/domain/repositories/payload_repository.dart';
import '../../domain/models/exploit_models.dart';

enum StudioStatus { idle, loading, success, error }

/// Controller for the Payload Configuration Studio: holds the form selection,
/// orchestrates payload generation against the backend agent, and auto-fills
/// the LHOST/LPORT defaults from the Settings page (stored securely).
class StudioController extends StateNotifier<StudioState> {
  StudioController(this._repository, this._storage) : super(const StudioState());

  final PayloadRepository _repository;
  final SecureStorageService _storage;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void setOs(String value) => state = state.copyWith(os: value);
  void setLanguage(String value) => state = state.copyWith(language: value);
  void setPerl(String value) => state = state.copyWith(perl: value);
  void setBypass(String value) => state = state.copyWith(bypass: value);
  void setEncoder(String value) => state = state.copyWith(encoder: value);
  void setAiPrompt(String value) => state = state.copyWith(aiPrompt: value);

  /// Pre-fill the studio from an exploit selected in the Exploit Library.
  /// Language is mapped to a supported studio language; the exploit's PoC
  /// description is injected as the AI prompt so generation stays grounded.
  void applyExploit(ExploitItem exploit) {
    final language = _mapLanguage(exploit.language);
    state = state.copyWith(
      language: language,
      bypass: 'Default',
      encoder: 'Auto',
      aiPrompt:
          'Use CVE ${exploit.cveId} (${exploit.service}) to craft a payload. '
          'Context: ${exploit.shortDescription}',
      status: StudioStatus.idle,
      clearResult: true,
    );
  }

  String _mapLanguage(String exploitLang) {
    switch (exploitLang.toLowerCase()) {
      case 'powershell':
        return 'PowerShell';
      case 'php':
        return 'PHP';
      case 'perl':
        return 'Perl';
      default:
        return 'Python';
    }
  }

  String _buildPrompt() {
    final s = state;
    final buffer = StringBuffer()
      ..writeln(
        'Generate a ${s.language} reverse shell for OS=${s.os}, '
        'bypass=${s.bypass}, encoding=${s.encoder}.',
      );
    if (s.aiPrompt.trim().isNotEmpty) {
      buffer.writeln('Additional instruction: ${s.aiPrompt.trim()}');
    }
    return buffer.toString();
  }

  Future<void> generate() async {
    if (_disposed) return;
    state = state.copyWith(status: StudioStatus.loading, result: null, error: null);
    try {
      final lhost = await _storage.readDefaultLhost();
      final lport = await _storage.readDefaultLport();
      final message = await _repository.execute(
        PayloadRequest(
          prompt: _buildPrompt(),
          lhost: lhost,
          lport: lport,
        ),
      );
      if (_disposed) return;
      state = state.copyWith(status: StudioStatus.success, result: message);
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(status: StudioStatus.error, error: e.toString());
    }
  }
}

class StudioState {
  const StudioState({
    this.os = 'Linux',
    this.language = 'Python',
    this.perl = 'Perl',
    this.bypass = 'Default',
    this.encoder = 'Auto',
    this.aiPrompt = '',
    this.status = StudioStatus.idle,
    this.result,
    this.error,
  });

  final String os;
  final String language;
  final String perl;
  final String bypass;
  final String encoder;
  final String aiPrompt;
  final StudioStatus status;
  final ChatMessage? result;
  final String? error;

  StudioState copyWith({
    String? os,
    String? language,
    String? perl,
    String? bypass,
    String? encoder,
    String? aiPrompt,
    StudioStatus? status,
    ChatMessage? result,
    String? error,
    bool clearResult = false,
  }) {
    return StudioState(
      os: os ?? this.os,
      language: language ?? this.language,
      perl: perl ?? this.perl,
      bypass: bypass ?? this.bypass,
      encoder: encoder ?? this.encoder,
      aiPrompt: aiPrompt ?? this.aiPrompt,
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      error: error ?? this.error,
    );
  }
}
