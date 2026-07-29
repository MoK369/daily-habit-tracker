sealed class Failure {
  final String? message;
  final Object? details;

  const Failure({this.message, this.details});
}

class StorageFailure extends Failure {
  const StorageFailure({super.message, super.details});
}

class ValidationFailure extends Failure {
  const ValidationFailure({super.message, super.details});
}

class DuplicateNameFailure extends Failure {
  const DuplicateNameFailure({super.message, super.details});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message, super.details});
}
