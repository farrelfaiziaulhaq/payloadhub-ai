import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/free_chatbot_service.dart';

enum FreeChatStatus { idle, loading, success, error }

/// State of the informational chatbot — completely ISOLATED from the payload
/// AI Agent Studio controller.
class FreeChatState {
  const FreeChatState({
    this.messages = const [],
    this.status = FreeChatStatus.idle,
  });

  final List<InfoMessage> messages;
  final FreeChatStatus status;

  FreeChatState copyWith({
    List<InfoMessage>? messages,
    FreeChatStatus? status,
  }) {
    return FreeChatState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
    );
  }
}

/// Controller for the read-only informational chatbot. It delegates only to
/// [FreeChatbotService] (plain chat completion) — never to the agent tools.
class FreeChatController extends StateNotifier<FreeChatState> {
  FreeChatController(this._service) : super(const FreeChatState());

  final FreeChatbotService _service;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> send(String text) async {
    if (_disposed) return;
    if (state.status == FreeChatStatus.loading) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final history = state.messages;
    final userMsg = InfoMessage(role: InfoRole.user, text: trimmed);
    final messages = [...history, userMsg];
    state = FreeChatState(messages: messages, status: FreeChatStatus.loading);

    try {
      final buffer = StringBuffer();
      await for (final chunk in _service.askStream(history, trimmed)) {
        if (_disposed) return;
        buffer.write(chunk);
        state = FreeChatState(
          messages: [
            ...messages,
            InfoMessage(role: InfoRole.assistant, text: buffer.toString()),
          ],
          status: FreeChatStatus.loading,
        );
      }
      if (_disposed) return;
      state = FreeChatState(
        messages: [
          ...messages,
          InfoMessage(role: InfoRole.assistant, text: buffer.toString().trim()),
        ],
        status: FreeChatStatus.success,
      );
    } catch (e) {
      if (_disposed) return;
      state = FreeChatState(
        messages: [
          ...messages,
          InfoMessage(role: InfoRole.assistant, text: '⚠️ $e'),
        ],
        status: FreeChatStatus.error,
      );
    }
  }

  void reset() => state = const FreeChatState();
}
