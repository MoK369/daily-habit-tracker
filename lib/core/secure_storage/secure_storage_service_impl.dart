import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../errors/exceptions.dart';
import 'secure_storage_service.dart';

@LazySingleton(as: SecureStorageService)
class SecureStorageServiceImpl implements SecureStorageService {
  SecureStorageServiceImpl(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> write({required String key, required String value}) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } on PlatformException catch (e) {
      throw SecureStorageException(e.message);
    } catch (e) {
      throw SecureStorageException(e.toString());
    }
  }

  @override
  Future<String?> read({required String key}) async {
    try {
      return await _secureStorage.read(key: key);
    } on PlatformException catch (e) {
      throw SecureStorageException(e.message);
    } catch (e) {
      throw SecureStorageException(e.toString());
    }
  }

  @override
  Future<void> delete({required String key}) async {
    try {
      await _secureStorage.delete(key: key);
    } on PlatformException catch (e) {
      throw SecureStorageException(e.message);
    } catch (e) {
      throw SecureStorageException(e.toString());
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } on PlatformException catch (e) {
      throw SecureStorageException(e.message);
    } catch (e) {
      throw SecureStorageException(e.toString());
    }
  }

  @override
  Future<bool> containsKey({required String key}) async {
    try {
      return await _secureStorage.containsKey(key: key);
    } on PlatformException catch (e) {
      throw SecureStorageException(e.message);
    } catch (e) {
      throw SecureStorageException(e.toString());
    }
  }
}
