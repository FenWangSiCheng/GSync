import '../../domain/repositories/git_token_repository.dart';
import '../datasources/secure_token_storage.dart';

class SecureGitTokenRepository implements GitTokenRepository {
  const SecureGitTokenRepository(this._storage);

  static const tokenKey = 'git_access_token';

  final SecureTokenStorage _storage;

  @override
  Future<String?> readToken() async {
    final token = await _storage.read(key: tokenKey);
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  @override
  Future<void> saveToken(String token) =>
      _storage.write(key: tokenKey, value: token.trim());

  @override
  Future<void> deleteToken() => _storage.delete(key: tokenKey);
}
