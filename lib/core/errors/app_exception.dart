abstract class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException(this.message, [this.prefix]);

  @override
  String toString() {
    return "${prefix ?? ''}$message";
  }
}

class NetworkException extends AppException {
  NetworkException([String message = "No internet connection"])
      : super(message, "Network Error: ");
}

class ServerException extends AppException {
  ServerException([String message = "Internal Server Error"])
      : super(message, "Server Error: ");
}

class CacheException extends AppException {
  CacheException([String message = "Cache Error"])
      : super(message, "Cache Error: ");
}

class AuthException extends AppException {
  AuthException([String message = "Authentication Failed"])
      : super(message, "Auth Error: ");
}
