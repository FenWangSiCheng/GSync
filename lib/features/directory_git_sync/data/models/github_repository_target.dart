import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;

class GitHubRepositoryTarget extends Equatable {
  const GitHubRepositoryTarget({
    required this.owner,
    required this.repo,
    required this.branch,
    required this.targetPath,
  });

  static const defaultBranch = 'main';

  final String owner;
  final String repo;
  final String branch;
  final String targetPath;

  GitHubRepositoryTarget copyWith({
    String? owner,
    String? repo,
    String? branch,
    String? targetPath,
  }) {
    return GitHubRepositoryTarget(
      owner: owner ?? this.owner,
      repo: repo ?? this.repo,
      branch: branch ?? this.branch,
      targetPath: targetPath ?? this.targetPath,
    );
  }

  factory GitHubRepositoryTarget.parse(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw const GitHubRepositoryTargetFormatException();
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      return _parseUri(uri);
    }

    final segments = trimmed
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.length == 2) {
      return GitHubRepositoryTarget(
        owner: segments[0],
        repo: _normalizeRepo(segments[1]),
        branch: defaultBranch,
        targetPath: '',
      );
    }

    throw const GitHubRepositoryTargetFormatException();
  }

  static GitHubRepositoryTarget _parseUri(Uri uri) {
    if (uri.host.toLowerCase() != 'github.com') {
      throw const GitHubRepositoryTargetFormatException();
    }

    final segments = uri.pathSegments
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    if (segments.length < 2) {
      throw const GitHubRepositoryTargetFormatException();
    }

    final owner = segments[0];
    final repo = _normalizeRepo(segments[1]);
    var branch = defaultBranch;
    var targetPath = '';

    if (segments.length > 2) {
      if (segments.length < 4 || segments[2] != 'tree') {
        throw const GitHubRepositoryTargetFormatException();
      }
      branch = segments[3];
      targetPath = _normalizeTargetPath(segments.skip(4).join('/'));
    }

    return GitHubRepositoryTarget(
      owner: owner,
      repo: repo,
      branch: branch,
      targetPath: targetPath,
    );
  }

  String contentPathFor(String relativePath) {
    final normalizedRelativePath = _normalizeTargetPath(relativePath);
    if (targetPath.isEmpty) return normalizedRelativePath;
    if (normalizedRelativePath.isEmpty) return targetPath;
    return p.posix.join(targetPath, normalizedRelativePath);
  }

  static String _normalizeRepo(String repo) {
    final normalized = repo.endsWith('.git')
        ? repo.substring(0, repo.length - 4)
        : repo;
    if (normalized.trim().isEmpty) {
      throw const GitHubRepositoryTargetFormatException();
    }
    return normalized;
  }

  static String _normalizeTargetPath(String path) {
    return path
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty && segment != '.')
        .join('/');
  }

  @override
  List<Object?> get props => [owner, repo, branch, targetPath];
}

class GitHubRepositoryTargetFormatException implements Exception {
  const GitHubRepositoryTargetFormatException();
}
