import '../repositories/git_token_repository.dart';

class SaveGitToken {
  const SaveGitToken(this._repository);

  final GitTokenRepository _repository;

  Future<void> call(String token) {
    final normalized = token.trim();
    if (normalized.isEmpty) {
      throw const SaveGitTokenException('请输入访问令牌。');
    }
    return _repository.saveToken(normalized);
  }
}

class SaveGitTokenException implements Exception {
  const SaveGitTokenException(this.message);

  final String message;
}
