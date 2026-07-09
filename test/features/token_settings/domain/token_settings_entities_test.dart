import 'package:flutter_foundations/features/token_settings/domain/repositories/git_token_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/entities/github_device_authorization.dart';
import 'package:flutter_foundations/features/token_settings/domain/entities/github_device_token_poll_result.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/github_device_flow_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/save_git_token.dart';
import 'package:flutter_foundations/features/token_settings/presentation/bloc/token_settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Token settings entities', () {
    test('state exposes device flow and delete availability', () {
      const empty = TokenSettingsState();
      final waiting = empty.copyWith(
        status: TokenSettingsStatus.waitingForAuthorization,
      );
      final saved = empty.copyWith(hasToken: true);

      expect(empty.canStartDeviceFlow, isTrue);
      expect(waiting.isBusy, isTrue);
      expect(waiting.canStartDeviceFlow, isFalse);
      expect(empty.canDelete, isFalse);
      expect(saved.canDelete, isTrue);
      expect(saved.props, [
        true,
        TokenSettingsStatus.idle,
        '正在检查访问令牌。',
        '',
        '',
      ]);
    });

    test('events expose value props', () {
      expect(const TokenSettingsStarted().props, isEmpty);
      expect(const TokenSettingsDeviceFlowRequested().props, isEmpty);
      expect(const TokenSettingsDeleteRequested().props, isEmpty);
    });

    test('save token validation rejects blank values', () async {
      const useCase = SaveGitToken(_NeverCalledGitTokenRepository());

      expect(() => useCase('   '), throwsA(isA<SaveGitTokenException>()));
    });

    test('device authorization exposes value props', () {
      final authorization = GitHubDeviceAuthorization(
        deviceCode: 'device-code',
        userCode: 'ABCD-1234',
        verificationUri: Uri.parse('https://github.com/login/device'),
        expiresIn: const Duration(minutes: 15),
        interval: const Duration(seconds: 5),
      );

      expect(authorization.props, [
        'device-code',
        'ABCD-1234',
        Uri.parse('https://github.com/login/device'),
        const Duration(minutes: 15),
        const Duration(seconds: 5),
      ]);
    });

    test('device token poll results expose value props', () {
      const authorized = GitHubDeviceTokenAuthorized(
        accessToken: 'token',
        tokenType: 'bearer',
        scope: 'repo',
      );
      const slowDown = GitHubDeviceTokenSlowDown(Duration(seconds: 10));

      expect(authorized.props, ['token', 'bearer', 'repo']);
      expect(const GitHubDeviceTokenPending().props, isEmpty);
      expect(slowDown.props, [const Duration(seconds: 10)]);
      expect(const GitHubDeviceTokenExpired().props, isEmpty);
      expect(const GitHubDeviceTokenDenied().props, isEmpty);
    });

    test('device flow exception string is readable', () {
      const error = GitHubDeviceFlowException('GitHub OAuth Client ID 未配置。');

      expect(error.toString(), 'GitHub OAuth Client ID 未配置。');
    });
  });
}

class _NeverCalledGitTokenRepository implements GitTokenRepository {
  const _NeverCalledGitTokenRepository();

  @override
  Future<String?> readToken() {
    throw StateError('readToken should not be called');
  }

  @override
  Future<void> saveToken(String token) {
    throw StateError('saveToken should not be called');
  }

  @override
  Future<void> deleteToken() {
    throw StateError('deleteToken should not be called');
  }
}
