import '../repositories/git_token_repository.dart';

class DeleteGitToken {
  const DeleteGitToken(this._repository);

  final GitTokenRepository _repository;

  Future<void> call() => _repository.deleteToken();
}
