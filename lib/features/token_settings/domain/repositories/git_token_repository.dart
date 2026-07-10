abstract class GitTokenRepository {
  Future<String?> readToken();

  Future<void> saveToken(String token);

  Future<void> deleteToken();
}
