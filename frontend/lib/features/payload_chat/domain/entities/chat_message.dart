/// A rendered code block returned by the agent.
class ChatCodeBlock {
  const ChatCodeBlock({required this.language, required this.code});

  final String language;
  final String code;
}

/// A single message in the chat transcript.
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.codeBlocks = const [],
  });

  final MessageRole role;
  final String content;
  final List<ChatCodeBlock> codeBlocks;

  bool get isUser => role == MessageRole.user;
}

enum MessageRole { user, assistant }
