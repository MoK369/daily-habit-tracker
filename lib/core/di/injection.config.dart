// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:claude_code/core/di/error_handler_module.dart' as _i818;
import 'package:claude_code/core/errors/error_handler.dart' as _i1026;
import 'package:claude_code/core/errors/exception_mapper.dart' as _i727;
import 'package:claude_code/core/errors/mappers/app_exception_mapper.dart'
    as _i701;
import 'package:claude_code/core/errors/mappers/hive_exception_mapper.dart'
    as _i565;
import 'package:claude_code/core/l10n/locale_manager.dart' as _i754;
import 'package:claude_code/core/secure_storage/secure_storage_module.dart'
    as _i253;
import 'package:claude_code/core/secure_storage/secure_storage_service.dart'
    as _i559;
import 'package:claude_code/core/secure_storage/secure_storage_service_impl.dart'
    as _i694;
import 'package:claude_code/core/theme/theme_manager.dart' as _i633;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    this.enableRegisteringMultipleInstancesOfOneType();
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final errorHandlerModule = _$ErrorHandlerModule();
    final secureStorageModule = _$SecureStorageModule();
    gh.lazySingleton<_i1026.ErrorHandler>(
      () => errorHandlerModule.errorHandler,
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => secureStorageModule.secureStorage,
    );
    gh.factory<_i727.ExceptionMapper>(() => _i701.AppExceptionMapper());
    gh.factory<_i727.ExceptionMapper>(() => _i565.HiveExceptionMapper());
    gh.lazySingleton<_i559.SecureStorageService>(
      () => _i694.SecureStorageServiceImpl(gh<_i558.FlutterSecureStorage>()),
    );
    gh.singleton<_i754.LocaleManager>(
      () => _i754.LocaleManager(gh<_i559.SecureStorageService>()),
    );
    gh.singleton<_i633.ThemeManager>(
      () => _i633.ThemeManager(gh<_i559.SecureStorageService>()),
    );
    return this;
  }
}

class _$ErrorHandlerModule extends _i818.ErrorHandlerModule {}

class _$SecureStorageModule extends _i253.SecureStorageModule {}
