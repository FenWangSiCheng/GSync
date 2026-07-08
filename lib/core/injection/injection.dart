import '../config/app_config.dart';
import '../network/dio_client.dart';
import 'injection.config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/datasources/git_command_runner.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/file_picker_directory_picker_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/fixture_git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/process_git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/directory_picker_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/pick_sync_directory.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/sync_directory_to_git_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/presentation/bloc/directory_sync_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;
AppConfig? _configuredAppConfig;

@InjectableInit()
Future<void> configureDependencies(AppConfig appConfig) async {
  _configuredAppConfig = appConfig;
  await getIt.init();
}

@module
abstract class RegisterModule {
  @singleton
  AppConfig get appConfig =>
      _configuredAppConfig ?? AppConfig.fromEnvironment();

  @preResolve
  @lazySingleton
  Future<DioClient> dioClient(AppConfig appConfig) async {
    final client = DioClient(appConfig);
    await client.initialize();
    return client;
  }

  @lazySingleton
  Dio dio(DioClient dioClient) => dioClient.dio;

  @lazySingleton
  GitCommandRunner gitCommandRunner() => const ProcessGitCommandRunner();

  @lazySingleton
  DirectoryPickerRepository directoryPickerRepository() {
    return const FilePickerDirectoryPickerRepository();
  }

  @lazySingleton
  GitSyncRepository gitSyncRepository(
    AppConfig appConfig,
    GitCommandRunner gitCommandRunner,
  ) {
    if (appConfig.mockApiDataSource) {
      return const FixtureGitSyncRepository();
    }
    return ProcessGitSyncRepository(gitCommandRunner);
  }

  @lazySingleton
  PickSyncDirectory pickSyncDirectory(
    DirectoryPickerRepository directoryPickerRepository,
  ) {
    return PickSyncDirectory(directoryPickerRepository);
  }

  @lazySingleton
  SyncDirectoryToGitRepository syncDirectoryToGitRepository(
    GitSyncRepository gitSyncRepository,
  ) {
    return SyncDirectoryToGitRepository(gitSyncRepository);
  }

  @injectable
  DirectorySyncBloc directorySyncBloc(
    PickSyncDirectory pickDirectory,
    SyncDirectoryToGitRepository syncDirectory,
  ) {
    return DirectorySyncBloc(
      pickDirectory: pickDirectory,
      syncDirectory: syncDirectory,
    );
  }
}
