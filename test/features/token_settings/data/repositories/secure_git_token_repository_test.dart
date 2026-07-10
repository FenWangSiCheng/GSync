import 'package:flutter_foundations/features/token_settings/data/datasources/secure_token_storage.dart';
import 'package:flutter_foundations/features/token_settings/data/repositories/secure_git_token_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecureGitTokenRepository', () {
    late _FakeSecureTokenStorage storage;
    late SecureGitTokenRepository repository;

    setUp(() {
      storage = _FakeSecureTokenStorage();
      repository = SecureGitTokenRepository(storage);
    });

    test('stores trimmed token values', () async {
      await repository.saveToken('  test-token  ');

      expect(storage.values[SecureGitTokenRepository.tokenKey], 'test-token');
      expect(await repository.readToken(), 'test-token');
    });

    test('reads missing or blank values as absent', () async {
      expect(await repository.readToken(), isNull);

      storage.values[SecureGitTokenRepository.tokenKey] = '   ';

      expect(await repository.readToken(), isNull);
    });

    test('deletes saved tokens', () async {
      await repository.saveToken('test-token');
      await repository.deleteToken();

      expect(await repository.readToken(), isNull);
    });
  });
}

class _FakeSecureTokenStorage implements SecureTokenStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }
}
