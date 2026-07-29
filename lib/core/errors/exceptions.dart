abstract class AppException implements Exception {
  final String? message;

  const AppException([this.message]);
}

class CacheException extends AppException {
  const CacheException([super.message]);
}

class DuplicateNameException extends AppException {
  const DuplicateNameException([super.message]);
}
