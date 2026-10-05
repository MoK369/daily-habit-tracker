import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:injectable/injectable.dart';

import '../app_failure.dart';
import '../exception_mapper.dart';
import '../exceptions.dart';

/// Maps everything Hive CE (and its underlying file I/O) can throw onto
/// [CacheFailure]. Hive has a single flat error type ([HiveError] — box not
/// found, box already open, corrupted checksum, unknown type adapter, ...)
/// with no subclasses to split further, plus raw [FileSystemException] from
/// the VM file backend when a failure isn't wrapped by Hive itself. Also
/// covers our own [CacheException], for cases a datasource wants to signal
/// a cache problem Hive doesn't model itself.
@Injectable(as: ExceptionMapper)
class HiveExceptionMapper implements ExceptionMapper {
  @override
  bool canHandle(Object exception) =>
      exception is HiveError ||
      exception is FileSystemException ||
      exception is CacheException;

  @override
  AppFailure map(Object exception, StackTrace stackTrace) {
    // Hive's own message (e.g. "Box not found...") is a technical/internal
    // string, not meant for end users — keep it out of `message` so the UI
    // mapper falls back to the localized generic "Something went wrong" copy.
    return CacheFailure(details: exception);
  }
}
