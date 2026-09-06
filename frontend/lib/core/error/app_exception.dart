/// Typed application errors surfaced to the UI layer.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Network / transport level failure (timeout, DNS, refused connection).
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Server returned a structured error (400 / 500 envelope).
class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});

  final int? statusCode;
}

/// Response body could not be parsed into the expected model.
class ParsingException extends AppException {
  const ParsingException(super.message);
}

/// A value failed client-side validation.
class ValidationException extends AppException {
  const ValidationException(super.message);
}
