import 'package:flutter_foundations/features/token_settings/domain/repositories/git_token_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/save_git_token.dart';
import 'package:flutter_foundations/features/token_settings/presentation/bloc/token_settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Token settings entities', () {
    test('state exposes save and delete availability', () {
      const empty = TokenSettingsState();
      final withInput = empty.copyWith(inputToken: 'token');
      final saving = withInput.copyWith(status: TokenSettingsStatus.saving);
      final saved = empty.copyWith(hasToken: true);

      expect(empty.canSave, isFalse);
      expect(withInput.canSave, isTrue);
      expect(saving.canSave, isFalse);
      expect(empty.canDelete, isFalse);
      expect(saved.canDelete, isTrue);
      expect(saved.props, ['', true, TokenSettingsStatus.idle, '正在检查访问令牌。']);
    });

    test('events expose value props', () {
      expect(const TokenSettingsStarted().props, isEmpty);
      expect(const TokenSettingsTokenChanged('token').props, ['token']);
      expect(const TokenSettingsSaveRequested().props, isEmpty);
      expect(const TokenSettingsDeleteRequested().props, isEmpty);
    });

    test('save token validation rejects blank values', () async {
      const useCase = SaveGitToken(_NeverCalledGitTokenRepository());

      expect(() => useCase('   '), throwsA(isA<SaveGitTokenException>()));
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
