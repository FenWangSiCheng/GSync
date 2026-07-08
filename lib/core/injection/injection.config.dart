// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_foundations/core/config/app_config.dart' as _i531;
import 'package:flutter_foundations/core/injection/injection.dart' as _i379;
import 'package:flutter_foundations/core/network/dio_client.dart' as _i542;
import 'package:flutter_foundations/core/router/app_router.dart' as _i177;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.singleton<_i531.AppConfig>(() => registerModule.appConfig);
    gh.lazySingleton<_i177.AppRouter>(() => _i177.AppRouter());
    await gh.lazySingletonAsync<_i542.DioClient>(
      () => registerModule.dioClient(gh<_i531.AppConfig>()),
      preResolve: true,
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.dio(gh<_i542.DioClient>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i379.RegisterModule {}
