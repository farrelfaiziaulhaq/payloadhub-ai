import '../../domain/entities/chat_message.dart';
import '../../../../core/error/app_exception.dart';

/// JSON model for the backend agent response.
class AgentResponseModel {
  AgentResponseModel({
    required this.status,
    required this.sessionId,
    required this.response,
    required this.codeBlocks,
    required this.toolsUsed,
  });

  final String status;
  final String sessionId;
  final String response;
  final List<AgentCodeBlockModel> codeBlocks;
  final List<String> toolsUsed;

  factory AgentResponseModel.fromJson(Map<String, dynamic> json) {
    final blocks = (json['code_blocks'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AgentCodeBlockModel.fromJson)
        .toList();
    final tools = (json['tools_used'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    return AgentResponseModel(
      status: json['status']?.toString() ?? 'success',
      sessionId: json['session_id']?.toString() ?? '',
      response: json['response']?.toString() ?? '',
      codeBlocks: blocks,
      toolsUsed: tools,
    );
  }

  /// Convert to a domain [ChatMessage] for the UI layer.
  ChatMessage toMessage() {
    if (status != 'success') {
      throw ParsingException('Unexpected response status: $status');
    }
    return ChatMessage(
      role: MessageRole.assistant,
      content: response,
      codeBlocks: codeBlocks
          .map((b) => ChatCodeBlock(language: b.language, code: b.code))
          .toList(),
    );
  }
}

class AgentCodeBlockModel {
  AgentCodeBlockModel({required this.language, required this.code});

  final String language;
  final String code;

  factory AgentCodeBlockModel.fromJson(Map<String, dynamic> json) {
    return AgentCodeBlockModel(
      language: json['language']?.toString() ?? 'text',
      code: json['code']?.toString() ?? '',
    );
  }
}
