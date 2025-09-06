/// Base exception class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message';
}

/// Exception thrown when environment configuration is invalid
class EnvironmentException extends AppException {
  const EnvironmentException(
    String message, {
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'EnvironmentException: $message';
}

/// Exception thrown during authentication operations
class AuthException extends AppException {
  const AuthException(
    String message, {
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'AuthException: $message';
}

/// Exception thrown during database operations
class DatabaseException extends AppException {
  const DatabaseException(
    String message, {
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'DatabaseException: $message';
}

/// Exception thrown during storage operations
class StorageException extends AppException {
  const StorageException(
    String message, {
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'StorageException: $message';
}

/// Exception thrown during validation
class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException(
    String message, {
    this.fieldErrors,
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  @override
  String toString() {
    final buffer = StringBuffer('ValidationException: $message');
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      buffer.write('\nField errors:');
      fieldErrors!.forEach((field, errors) {
        buffer.write('\n  $field: ${errors.join(', ')}');
      });
    }
    return buffer.toString();
  }
}

/// Exception thrown during network operations
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException(
    String message, {
    this.statusCode,
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'NetworkException: $message (Status: $statusCode)';
}

/// Exception thrown when a resource is not found
class NotFoundException extends AppException {
  const NotFoundException(
    String message, {
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'NotFoundException: $message';
}

/// Exception thrown when access is forbidden
class ForbiddenException extends AppException {
  const ForbiddenException(
    String message, {
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'ForbiddenException: $message';
}