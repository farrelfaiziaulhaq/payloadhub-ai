import 'package:dio/dio.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/entities/chat_message.dart';
import '../domain/repositories/payload_repository.dart';
import 'models/agent_request.dart';
import 'models/agent_response.dart';

/// Concrete repository that talks to the FastAPI backend over HTTP (Dio).
class PayloadRepositoryImpl implements PayloadRepository {
  PayloadRepositoryImpl(this._dioClient);

  final DioClient _dioClient;

  static const _executePath = '/api/v1/agent/execute';

  @override
  Future<ChatMessage> execute(PayloadRequest request) async {
    final model = AgentRequestModel(
      prompt: request.prompt,
      lhost: request.lhost,
      lport: request.lport,
      target: request.target,
      scanData: request.scanData,
    );

    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        _executePath,
        data: model.toJson(),
      );

      final data = response.data;
      if (data == null) {
        throw const ParsingException('Empty response body.');
      }
      return AgentResponseModel.fromJson(data).toMessage();
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error! as AppException;
      }
      throw NetworkException('Request failed: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ParsingException('Failed to parse agent response: $e');
    }
  }
}
