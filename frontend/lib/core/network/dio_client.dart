import 'package:dio/dio.dart';

import '../error/app_exception.dart';

/// Centralised Dio client with an error-mapping interceptor.
///
/// Every exception thrown by the repository is normalised into an
/// [AppException] so the presentation layer never deals with raw [DioException].
class DioClient {
  DioClient(
      {required String baseUrl, Duration timeout = const Duration(seconds: 30)})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: timeout,
            receiveTimeout: timeout,
            sendTimeout: timeout,
            headers: const {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(_ErrorInterceptor());
  }

  final Dio _dio;

  Dio get dio => _dio;
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final AppException mapped = _map(err);
    handler.next(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: mapped,
    ));
  }

  AppException _map(DioException err) {
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException('Connection timed out. Please retry.');
      case DioExceptionType.connectionError:
        return const NetworkException(
            'Cannot reach the backend. Check your network / base URL.');
      case DioExceptionType.badResponse:
        if (data is Map && data['detail'] is List) {
          final details = (data['detail'] as List)
              .map((e) => e is Map ? (e['msg'] ?? '') : e.toString())
              .join('\n');
          return ServerException(details.isEmpty ? 'Invalid request.' : details,
              statusCode: statusCode);
        }
        if (data is Map && data['detail'] is String) {
          return ServerException(data['detail'] as String,
              statusCode: statusCode);
        }
        return ServerException('Server error (HTTP $statusCode).',
            statusCode: statusCode);
      case DioExceptionType.cancel:
        return const NetworkException('Request cancelled.');
      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
        return const NetworkException('Unexpected network error.');
    }
  }
}
