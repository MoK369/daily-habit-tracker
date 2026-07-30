import 'dart:async' show FutureOr;
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit()
FutureOr<GetIt> configureDependencies() async => getIt.init();
