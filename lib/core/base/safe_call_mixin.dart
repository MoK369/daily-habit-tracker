import 'dart:async';

import 'package:flutter/foundation.dart';

import '../errors/error_handler.dart';
import 'base_response.dart';

mixin SafeCallMixin {
  ErrorHandler get errorHandler;

  Future<BaseResponse<T>> safeCall<T>(FutureOr<T> Function() action) async {
    try {
      final result = await action();
      return SuccessResponse<T>(result);
    } catch (e, s) {
      return ErrorResponse<T>(errorHandler.handle(e, s));
    }
  }

  Future<T?> safeCallOrNull<T>(FutureOr<T> Function() action) async {
    try {
      return await action();
    } catch (e, s) {
      debugPrint('Dropped failure: ${errorHandler.handle(e, s).details}');
      return null;
    }
  }
}
