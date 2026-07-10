import 'package:flutter_foundations/features/directory_git_sync/data/models/github_repository_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubRepositoryTarget', () {
    test('parses a GitHub repository root URL', () {
      final target = GitHubRepositoryTarget.parse(
        'https://github.com/octocat/notes',
      );

      expect(target.owner, 'octocat');
      expect(target.repo, 'notes');
      expect(target.branch, 'main');
      expect(target.targetPath, isEmpty);
      expect(target.contentPathFor('daily/today.md'), 'daily/today.md');
    });

    test('parses a GitHub branch directory URL', () {
      final target = GitHubRepositoryTarget.parse(
        'https://github.com/octocat/notes/tree/main/mobile/backups',
      );

      expect(target.owner, 'octocat');
      expect(target.repo, 'notes');
      expect(target.branch, 'main');
      expect(target.targetPath, 'mobile/backups');
      expect(
        target.contentPathFor('daily/today.md'),
        'mobile/backups/daily/today.md',
      );
    });

    test('parses shorthand owner and repo input', () {
      final target = GitHubRepositoryTarget.parse('octocat/notes.git');

      expect(target.owner, 'octocat');
      expect(target.repo, 'notes');
      expect(target.branch, 'main');
      expect(target.targetPath, isEmpty);
    });

    test('rejects non-GitHub URLs', () {
      expect(
        () => GitHubRepositoryTarget.parse('https://example.com/octocat/notes'),
        throwsA(isA<GitHubRepositoryTargetFormatException>()),
      );
    });
  });
}
