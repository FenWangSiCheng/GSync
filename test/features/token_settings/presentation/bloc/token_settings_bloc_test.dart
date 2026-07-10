import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_foundations/features/token_settings/domain/entities/github_device_authorization.dart';
import 'package:flutter_foundations/features/token_settings/domain/entities/github_device_token_poll_result.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/git_token_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/github_device_flow_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/delete_git_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/get_git_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/poll_github_device_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/request_github_device_authorization.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/save_git_token.dart';
import 'package:flutter_foundations/features/token_settings/presentation/bloc/token_settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TokenSettingsBloc', () {
    late _FakeGitTokenRepository tokenRepository;
    late _FakeGitHubDeviceFlowRepository deviceFlowRepository;

    setUp(() {
      tokenRepository = _FakeGitTokenRepository();
      deviceFlowRepository = _FakeGitHubDeviceFlowRepository();
    });

    TokenSettingsBloc buildBloc() {
      return TokenSettingsBloc(
        getGitToken: GetGitToken(tokenRepository),
        saveGitToken: SaveGitToken(tokenRepository),
        deleteGitToken: DeleteGitToken(tokenRepository),
        requestDeviceAuthorization: RequestGitHubDeviceAuthorization(
          deviceFlowRepository,
        ),
        pollDeviceToken: PollGitHubDeviceToken(deviceFlowRepository),
      );
    }

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'loads existing authorization status',
      build: () {
        tokenRepository.token = 'test-token';
        return buildBloc();
      },
      act: (bloc) => bloc.add(const TokenSettingsStarted()),
      expect: () => [
        isA<TokenSettingsState>()
            .having((state) => state.hasToken, 'hasToken', isTrue)
            .having(
              (state) => state.statusMessage,
              'statusMessage',
              'GitHub 授权已安全保存。',
            ),
      ],
    );

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'requests a device code, polls, and stores the authorized token',
      build: () {
        deviceFlowRepository.pollResults = const [
          GitHubDeviceTokenPending(),
          GitHubDeviceTokenAuthorized(
            accessToken: '  gho-token  ',
            tokenType: 'bearer',
            scope: 'repo',
          ),
        ];
        return buildBloc();
      },
      act: (bloc) => bloc.add(const TokenSettingsDeviceFlowRequested()),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.requestingDeviceCode,
        ),
        isA<TokenSettingsState>()
            .having(
              (state) => state.status,
              'status',
              TokenSettingsStatus.waitingForAuthorization,
            )
            .having((state) => state.userCode, 'userCode', 'ABCD-1234')
            .having(
              (state) => state.verificationUri,
              'verificationUri',
              'https://github.com/login/device',
            ),
        isA<TokenSettingsState>().having(
          (state) => state.statusMessage,
          'statusMessage',
          '正在等待 GitHub 授权完成。',
        ),
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.saving,
        ),
        isA<TokenSettingsState>()
            .having((state) => state.hasToken, 'hasToken', isTrue)
            .having(
              (state) => state.status,
              'status',
              TokenSettingsStatus.saved,
            ),
      ],
      verify: (_) {
        expect(tokenRepository.token, 'gho-token');
      },
    );

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'reports missing client id failures',
      build: () {
        deviceFlowRepository.requestError = const GitHubDeviceFlowException(
          'GitHub OAuth Client ID 未配置。',
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const TokenSettingsDeviceFlowRequested()),
      expect: () => [
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.requestingDeviceCode,
        ),
        isA<TokenSettingsState>()
            .having(
              (state) => state.status,
              'status',
              TokenSettingsStatus.failure,
            )
            .having(
              (state) => state.statusMessage,
              'statusMessage',
              'GitHub OAuth Client ID 未配置。',
            ),
      ],
    );

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'reports expired device codes',
      build: () {
        deviceFlowRepository.pollResults = const [GitHubDeviceTokenExpired()];
        return buildBloc();
      },
      act: (bloc) => bloc.add(const TokenSettingsDeviceFlowRequested()),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.requestingDeviceCode,
        ),
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.waitingForAuthorization,
        ),
        isA<TokenSettingsState>()
            .having(
              (state) => state.status,
              'status',
              TokenSettingsStatus.failure,
            )
            .having(
              (state) => state.statusMessage,
              'statusMessage',
              '设备码已过期,请重新开始 GitHub 授权。',
            ),
      ],
    );

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'reports denied authorization',
      build: () {
        deviceFlowRepository.pollResults = const [GitHubDeviceTokenDenied()];
        return buildBloc();
      },
      act: (bloc) => bloc.add(const TokenSettingsDeviceFlowRequested()),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.requestingDeviceCode,
        ),
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.waitingForAuthorization,
        ),
        isA<TokenSettingsState>()
            .having(
              (state) => state.status,
              'status',
              TokenSettingsStatus.failure,
            )
            .having(
              (state) => state.statusMessage,
              'statusMessage',
              'GitHub 授权已取消。',
            ),
      ],
    );

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'deletes saved authorization',
      build: () {
        tokenRepository.token = 'test-token';
        return buildBloc();
      },
      seed: () => const TokenSettingsState(hasToken: true),
      act: (bloc) => bloc.add(const TokenSettingsDeleteRequested()),
      expect: () => [
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.saving,
        ),
        isA<TokenSettingsState>()
            .having((state) => state.hasToken, 'hasToken', isFalse)
            .having(
              (state) => state.status,
              'status',
              TokenSettingsStatus.deleted,
            ),
      ],
      verify: (_) {
        expect(tokenRepository.token, isNull);
      },
    );
  });
}

class _FakeGitTokenRepository implements GitTokenRepository {
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String token) async {
    this.token = token.trim();
  }

  @override
  Future<void> deleteToken() async {
    token = null;
  }
}

class _FakeGitHubDeviceFlowRepository implements GitHubDeviceFlowRepository {
  GitHubDeviceFlowException? requestError;
  List<GitHubDeviceTokenPollResult> pollResults = const [
    GitHubDeviceTokenAuthorized(
      accessToken: 'test-token',
      tokenType: 'bearer',
      scope: 'repo',
    ),
  ];

  var _pollIndex = 0;

  @override
  Future<GitHubDeviceAuthorization> requestAuthorization() async {
    final error = requestError;
    if (error != null) throw error;
    return GitHubDeviceAuthorization(
      deviceCode: 'device-code',
      userCode: 'ABCD-1234',
      verificationUri: Uri.parse('https://github.com/login/device'),
      expiresIn: const Duration(minutes: 15),
      interval: Duration.zero,
    );
  }

  @override
  Future<GitHubDeviceTokenPollResult> pollToken({
    required String deviceCode,
  }) async {
    final result = pollResults[_pollIndex];
    if (_pollIndex < pollResults.length - 1) {
      _pollIndex += 1;
    }
    return result;
  }
}
