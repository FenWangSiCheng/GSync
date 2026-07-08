import '../config/app_config.dart';
import '../network/dio_client.dart';
import 'injection.config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/datasources/git_command_runner.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/datasources/github_contents_api.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/app_documents_default_sync_directory_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/file_picker_directory_picker_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/fixture_git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/github_api_git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/default_sync_directory_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/directory_picker_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/get_default_sync_directory.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/pick_sync_directory.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/sync_directory_to_git_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/presentation/bloc/directory_sync_bloc.dart';
import 'package:flutter_foundations/features/token_settings/data/datasources/secure_token_storage.dart';
import 'package:flutter_foundations/features/token_settings/data/repositories/secure_git_token_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/git_token_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/delete_git_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/get_git_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/save_git_token.dart';
import 'package:flutter_foundations/features/token_settings/presentation/bloc/token_settings_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
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
  http.Client httpClient() => http.Client();

  @lazySingleton
  GitHubContentsApi gitHubContentsApi(http.Client client) {
    return GitHubContentsApi(client);
  }

  @lazySingleton
  GitCommandRunner gitCommandRunner() => const ProcessGitCommandRunner();

  @lazySingleton
  FlutterSecureStorage flutterSecureStorage() {
    return const FlutterSecureStorage();
  }

  @lazySingleton
  SecureTokenStorage secureTokenStorage(FlutterSecureStorage storage) {
    return FlutterSecureTokenStorage(storage);
  }

  @lazySingleton
  GitTokenRepository gitTokenRepository(SecureTokenStorage storage) {
    return SecureGitTokenRepository(storage);
  }

  @lazySingleton
  DefaultSyncDirectoryRepository defaultSyncDirectoryRepository() {
    return const AppDocumentsDefaultSyncDirectoryRepository();
  }

  @lazySingleton
  DirectoryPickerRepository directoryPickerRepository() {
    return const FilePickerDirectoryPickerRepository();
  }

  @lazySingleton
  GitSyncRepository gitSyncRepository(
    AppConfig appConfig,
    GitHubContentsApi gitHubContentsApi,
  ) {
    if (appConfig.mockApiDataSource) {
      return const FixtureGitSyncRepository();
    }
    return GithubApiGitSyncRepository(gitHubContentsApi);
  }

  @lazySingleton
  PickSyncDirectory pickSyncDirectory(
    DirectoryPickerRepository directoryPickerRepository,
  ) {
    return PickSyncDirectory(directoryPickerRepository);
  }

  @lazySingleton
  GetDefaultSyncDirectory getDefaultSyncDirectory(
    DefaultSyncDirectoryRepository defaultSyncDirectoryRepository,
  ) {
    return GetDefaultSyncDirectory(defaultSyncDirectoryRepository);
  }

  @lazySingleton
  GetGitToken getGitToken(GitTokenRepository gitTokenRepository) {
    return GetGitToken(gitTokenRepository);
  }

  @lazySingleton
  SaveGitToken saveGitToken(GitTokenRepository gitTokenRepository) {
    return SaveGitToken(gitTokenRepository);
  }

  @lazySingleton
  DeleteGitToken deleteGitToken(GitTokenRepository gitTokenRepository) {
    return DeleteGitToken(gitTokenRepository);
  }

  @lazySingleton
  SyncDirectoryToGitRepository syncDirectoryToGitRepository(
    GitSyncRepository gitSyncRepository,
  ) {
    return SyncDirectoryToGitRepository(gitSyncRepository);
  }

  @injectable
  DirectorySyncBloc directorySyncBloc(
    GetDefaultSyncDirectory getDefaultDirectory,
    PickSyncDirectory pickDirectory,
    GetGitToken getGitToken,
    SyncDirectoryToGitRepository syncDirectory,
  ) {
    return DirectorySyncBloc(
      getDefaultDirectory: getDefaultDirectory,
      pickDirectory: pickDirectory,
      getGitToken: getGitToken,
      syncDirectory: syncDirectory,
    );
  }

  @injectable
  TokenSettingsBloc tokenSettingsBloc(
    GetGitToken getGitToken,
    SaveGitToken saveGitToken,
    DeleteGitToken deleteGitToken,
  ) {
    return TokenSettingsBloc(
      getGitToken: getGitToken,
      saveGitToken: saveGitToken,
      deleteGitToken: deleteGitToken,
    );
  }
}
