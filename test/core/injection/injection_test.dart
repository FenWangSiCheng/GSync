import 'package:dio/dio.dart';
import 'package:flutter_foundations/core/config/app_config.dart';
import 'package:flutter_foundations/core/injection/injection.dart';
import 'package:flutter_foundations/core/network/dio_client.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/datasources/directory_access_scope.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/datasources/git_command_runner.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/datasources/github_contents_api.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/datasources/github_repository_catalog_api.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/default_sync_directory_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/fixture_github_repository_catalog_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/fixture_git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/github_api_git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/github_api_repository_catalog_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/directory_picker_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/github_repository_catalog_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/get_default_sync_directory.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/load_github_repositories.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/load_github_repository_branches.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/pick_sync_directory.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/sync_directory_to_git_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/presentation/bloc/directory_sync_bloc.dart';
import 'package:flutter_foundations/features/token_settings/data/datasources/github_device_flow_api.dart';
import 'package:flutter_foundations/features/token_settings/data/repositories/fixture_github_device_flow_repository.dart';
import 'package:flutter_foundations/features/token_settings/data/repositories/github_api_device_flow_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/git_token_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/github_device_flow_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/delete_git_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/get_git_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/poll_github_device_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/request_github_device_authorization.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/save_git_token.dart';
import 'package:flutter_foundations/features/token_settings/presentation/bloc/token_settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('Dependency Injection', () {
    setUp(() async {
      // Reset GetIt before each test
      await getIt.reset();
    });

    tearDown(() async {
      await getIt.reset();
    });

    test('configureDependencies should register AppConfig', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.dev);

      await configureDependencies(testConfig);

      expect(getIt.isRegistered<AppConfig>(), true);
      expect(getIt.get<AppConfig>(), testConfig);
    });

    test('configureDependencies should register DioClient', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.prod);

      await configureDependencies(testConfig);

      expect(getIt.isRegistered<DioClient>(), true);
      expect(getIt<DioClient>(), isA<DioClient>());
    });

    test('configureDependencies should register Dio instance', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.prod);

      await configureDependencies(testConfig);

      expect(getIt.isRegistered<Dio>(), true);
      expect(getIt<Dio>(), isA<Dio>());
    });

    test('Dio instance should be obtained from DioClient', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.prod);

      await configureDependencies(testConfig);

      final dioClient = getIt<DioClient>();
      final dio = getIt<Dio>();

      expect(dio, same(dioClient.dio));
    });

    test('DioClient should be initialized with correct AppConfig', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.dev);

      await configureDependencies(testConfig);

      final dioClient = getIt<DioClient>();

      // Verify DioClient was initialized with correct config
      expect(dioClient.dio.options.baseUrl, testConfig.baseUrl);
    });

    test('should handle reconfiguration after reset', () async {
      const config1 = AppConfig(currentFlavor: Flavor.dev);

      await configureDependencies(config1);

      expect(getIt.isRegistered<AppConfig>(), true);
      expect(getIt.get<AppConfig>().currentFlavor, Flavor.dev);

      // Reset and configure again with different config
      await getIt.reset();

      const config2 = AppConfig(currentFlavor: Flavor.prod);
      await configureDependencies(config2);

      expect(getIt.isRegistered<AppConfig>(), true);
      expect(getIt.get<AppConfig>().currentFlavor, Flavor.prod);
    });

    test('DioClient should be singleton', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.prod);

      await configureDependencies(testConfig);

      final dioClient1 = getIt<DioClient>();
      final dioClient2 = getIt<DioClient>();

      expect(dioClient1, same(dioClient2));
    });

    test('Dio should be singleton', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.prod);

      await configureDependencies(testConfig);

      final dio1 = getIt<Dio>();
      final dio2 = getIt<Dio>();

      expect(dio1, same(dio2));
    });

    test('registers directory sync dependencies for dev fixtures', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.dev);

      await configureDependencies(testConfig);

      expect(getIt<GitCommandRunner>(), isA<ProcessGitCommandRunner>());
      expect(
        getIt<DirectoryAccessScope>(),
        isA<PlatformDirectoryAccessScope>(),
      );
      expect(getIt<http.Client>(), isA<http.Client>());
      expect(getIt<GitHubContentsApi>(), isA<GitHubContentsApi>());
      expect(
        getIt<GitHubRepositoryCatalogApi>(),
        isA<GitHubRepositoryCatalogApi>(),
      );
      expect(getIt<GitHubDeviceFlowApi>(), isA<GitHubDeviceFlowApi>());
      expect(
        getIt<DefaultSyncDirectoryRepository>(),
        isA<DefaultSyncDirectoryRepository>(),
      );
      expect(
        getIt<DirectoryPickerRepository>(),
        isA<DirectoryPickerRepository>(),
      );
      expect(getIt<GitTokenRepository>(), isA<GitTokenRepository>());
      expect(getIt<GetDefaultSyncDirectory>(), isA<GetDefaultSyncDirectory>());
      expect(getIt<GetGitToken>(), isA<GetGitToken>());
      expect(getIt<SaveGitToken>(), isA<SaveGitToken>());
      expect(getIt<DeleteGitToken>(), isA<DeleteGitToken>());
      expect(
        getIt<GitHubDeviceFlowRepository>(),
        isA<FixtureGitHubDeviceFlowRepository>(),
      );
      expect(
        getIt<RequestGitHubDeviceAuthorization>(),
        isA<RequestGitHubDeviceAuthorization>(),
      );
      expect(getIt<PollGitHubDeviceToken>(), isA<PollGitHubDeviceToken>());
      expect(getIt<GitSyncRepository>(), isA<FixtureGitSyncRepository>());
      expect(
        getIt<GitHubRepositoryCatalogRepository>(),
        isA<FixtureGitHubRepositoryCatalogRepository>(),
      );
      expect(getIt<LoadGitHubRepositories>(), isA<LoadGitHubRepositories>());
      expect(
        getIt<LoadGitHubRepositoryBranches>(),
        isA<LoadGitHubRepositoryBranches>(),
      );
      expect(getIt<PickSyncDirectory>(), isA<PickSyncDirectory>());
      expect(
        getIt<SyncDirectoryToGitRepository>(),
        isA<SyncDirectoryToGitRepository>(),
      );
      expect(getIt<DirectorySyncBloc>(), isA<DirectorySyncBloc>());
      expect(getIt<TokenSettingsBloc>(), isA<TokenSettingsBloc>());
      expect(
        getIt<DirectorySyncBloc>(),
        isNot(same(getIt<DirectorySyncBloc>())),
      );
    });

    test('registers GitHub API sync repository outside dev fixtures', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.prod);

      await configureDependencies(testConfig);

      expect(
        getIt<DirectoryAccessScope>(),
        isA<PlatformDirectoryAccessScope>(),
      );
      expect(getIt<GitSyncRepository>(), isA<GithubApiGitSyncRepository>());
      expect(
        getIt<GitHubRepositoryCatalogRepository>(),
        isA<GitHubApiRepositoryCatalogRepository>(),
      );
      expect(
        getIt<GitHubDeviceFlowRepository>(),
        isA<GitHubApiDeviceFlowRepository>(),
      );
    });
  });
}
