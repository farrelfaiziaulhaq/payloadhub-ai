import '../entities/chat_message.dart';

/// Input bundle for a single agent execution.
class PayloadRequest {
  const PayloadRequest({
    required this.prompt,
    this.lhost,
    this.lport,
    this.target,
    this.scanData,
  });

  final String prompt;
  final String? lhost;
  final int? lport;
  final String? target;
  final String? scanData;
}

/// Domain-level abstraction for the payload backend.
abstract class PayloadRepository {
  Future<ChatMessage> execute(PayloadRequest request);
}
