import '../errors/app_failure.dart';

sealed class BaseResponse<T> {
  const BaseResponse();
}

final class SuccessResponse<T> extends BaseResponse<T> {
  final T data;

  const SuccessResponse(this.data);
}

final class ErrorResponse<T> extends BaseResponse<T> {
  final AppFailure failure;

  const ErrorResponse(this.failure);
}
