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
import 'package:flutter_foundations/features/directory_git_sync/data/datasources/git_command_runner.dart'
    as _i873;
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/default_sync_directory_repository.dart'
    as _i79;
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/directory_picker_repository.dart'
    as _i925;
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/git_sync_repository.dart'
    as _i451;
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/get_default_sync_directory.dart'
    as _i789;
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/pick_sync_directory.dart'
    as _i142;
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/sync_directory_to_git_repository.dart'
    as _i320;
import 'package:flutter_foundations/features/directory_git_sync/presentation/bloc/directory_sync_bloc.dart'
    as _i745;
import 'package:flutter_foundations/features/token_settings/data/datasources/secure_token_storage.dart'
    as _i772;
import 'package:flutter_foundations/features/token_settings/domain/repositories/git_token_repository.dart'
    as _i282;
import 'package:flutter_foundations/features/token_settings/domain/usecases/delete_git_token.dart'
    as _i929;
import 'package:flutter_foundations/features/token_settings/domain/usecases/get_git_token.dart'
    as _i763;
import 'package:flutter_foundations/features/token_settings/domain/usecases/save_git_token.dart'
    as _i388;
import 'package:flutter_foundations/features/token_settings/presentation/bloc/token_settings_bloc.dart'
    as _i312;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
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
    gh.lazySingleton<_i873.GitCommandRunner>(
      () => registerModule.gitCommandRunner(),
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.flutterSecureStorage(),
    );
    gh.lazySingleton<_i79.DefaultSyncDirectoryRepository>(
      () => registerModule.defaultSyncDirectoryRepository(),
    );
    gh.lazySingleton<_i925.DirectoryPickerRepository>(
      () => registerModule.directoryPickerRepository(),
    );
    gh.lazySingleton<_i177.AppRouter>(() => _i177.AppRouter());
    gh.lazySingleton<_i772.SecureTokenStorage>(
      () => registerModule.secureTokenStorage(gh<_i558.FlutterSecureStorage>()),
    );
    await gh.lazySingletonAsync<_i542.DioClient>(
      () => registerModule.dioClient(gh<_i531.AppConfig>()),
      preResolve: true,
    );
    gh.lazySingleton<_i282.GitTokenRepository>(
      () => registerModule.gitTokenRepository(gh<_i772.SecureTokenStorage>()),
    );
    gh.lazySingleton<_i789.GetDefaultSyncDirectory>(
      () => registerModule.getDefaultSyncDirectory(
        gh<_i79.DefaultSyncDirectoryRepository>(),
      ),
    );
    gh.lazySingleton<_i142.PickSyncDirectory>(
      () => registerModule.pickSyncDirectory(
        gh<_i925.DirectoryPickerRepository>(),
      ),
    );
    gh.lazySingleton<_i451.GitSyncRepository>(
      () => registerModule.gitSyncRepository(
        gh<_i531.AppConfig>(),
        gh<_i873.GitCommandRunner>(),
      ),
    );
    gh.lazySingleton<_i320.SyncDirectoryToGitRepository>(
      () => registerModule.syncDirectoryToGitRepository(
        gh<_i451.GitSyncRepository>(),
      ),
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.dio(gh<_i542.DioClient>()),
    );
    gh.lazySingleton<_i763.GetGitToken>(
      () => registerModule.getGitToken(gh<_i282.GitTokenRepository>()),
    );
    gh.lazySingleton<_i388.SaveGitToken>(
      () => registerModule.saveGitToken(gh<_i282.GitTokenRepository>()),
    );
    gh.lazySingleton<_i929.DeleteGitToken>(
      () => registerModule.deleteGitToken(gh<_i282.GitTokenRepository>()),
    );
    gh.factory<_i745.DirectorySyncBloc>(
      () => registerModule.directorySyncBloc(
        gh<_i789.GetDefaultSyncDirectory>(),
        gh<_i142.PickSyncDirectory>(),
        gh<_i763.GetGitToken>(),
        gh<_i320.SyncDirectoryToGitRepository>(),
      ),
    );
    gh.factory<_i312.TokenSettingsBloc>(
      () => registerModule.tokenSettingsBloc(
        gh<_i763.GetGitToken>(),
        gh<_i388.SaveGitToken>(),
        gh<_i929.DeleteGitToken>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i379.RegisterModule {}
