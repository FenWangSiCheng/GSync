import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/git_token_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/delete_git_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/get_git_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/save_git_token.dart';
import 'package:flutter_foundations/features/token_settings/presentation/bloc/token_settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TokenSettingsBloc', () {
    late _FakeGitTokenRepository repository;

    setUp(() {
      repository = _FakeGitTokenRepository();
    });

    TokenSettingsBloc buildBloc() {
      return TokenSettingsBloc(
        getGitToken: GetGitToken(repository),
        saveGitToken: SaveGitToken(repository),
        deleteGitToken: DeleteGitToken(repository),
      );
    }

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'loads existing token status',
      build: () {
        repository.token = 'test-token';
        return buildBloc();
      },
      act: (bloc) => bloc.add(const TokenSettingsStarted()),
      expect: () => [
        isA<TokenSettingsState>()
            .having((state) => state.hasToken, 'hasToken', isTrue)
            .having(
              (state) => state.statusMessage,
              'statusMessage',
              '访问令牌已安全保存。',
            ),
      ],
    );

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'saves a trimmed token',
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(const TokenSettingsTokenChanged('  test-token  '))
          ..add(const TokenSettingsSaveRequested());
      },
      expect: () => [
        isA<TokenSettingsState>().having(
          (state) => state.inputToken,
          'inputToken',
          '  test-token  ',
        ),
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.saving,
        ),
        isA<TokenSettingsState>()
            .having((state) => state.hasToken, 'hasToken', isTrue)
            .having((state) => state.inputToken, 'inputToken', isEmpty)
            .having(
              (state) => state.status,
              'status',
              TokenSettingsStatus.saved,
            ),
      ],
      verify: (_) {
        expect(repository.token, 'test-token');
      },
    );

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'deletes a saved token',
      build: () {
        repository.token = 'test-token';
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
        expect(repository.token, isNull);
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
    this.token = token;
  }

  @override
  Future<void> deleteToken() async {
    token = null;
  }
}
