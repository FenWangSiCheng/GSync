import '../repositories/git_token_repository.dart';

class GetGitToken {
  const GetGitToken(this._repository);

  final GitTokenRepository _repository;

  Future<String?> call() => _repository.readToken();
}
