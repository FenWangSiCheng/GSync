import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Harness structure', () {
    test('required harness files exist', () {
      const paths = [
        'AGENTS.md',
        'feature_list.json',
        'progress.md',
        'init.sh',
        'session-handoff.md',
        '.github/workflows/harness.yml',
        'docs/harness/README.md',
        'docs/harness/ARCHITECTURE.md',
        'docs/harness/VALIDATION.md',
        'docs/harness/QUALITY.md',
        'docs/harness/OPERABILITY.md',
        'docs/harness/TASKS.md',
        'tool/harness.dart',
      ];

      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: '$path should exist');
      }
    });

    test(
      'agent instructions route state, verification, scope, and lifecycle',
      () {
        final agents = File('AGENTS.md').readAsStringSync();

        expect(agents, contains('Startup Workflow'));
        expect(agents, contains('Definition of Done'));
        expect(agents, contains('Verification Commands'));
        expect(agents, contains('End of Session'));
        expect(agents, contains('One feature at a time'));
        expect(agents, contains('feature_list.json'));
        expect(agents, contains('progress.md'));
        expect(agents, contains('session-handoff.md'));
      },
    );

    test('feature list is valid walkinglabs state', () {
      final decoded =
          jsonDecode(File('feature_list.json').readAsStringSync())
              as Map<String, Object?>;
      final features = decoded['features'] as List<Object?>;

      expect(features, isNotEmpty);
      for (final feature in features.cast<Map<String, Object?>>()) {
        expect(feature['id'], isA<String>());
        expect(feature['name'], isA<String>());
        expect(feature['description'], isA<String>());
        expect(feature['dependencies'], isA<List<Object?>>());
        expect(feature['status'], isA<String>());
        expect(feature.containsKey('evidence'), isTrue);
      }
    });

    test('session lifecycle artifacts support restart and evidence', () {
      final progress = File('progress.md').readAsStringSync();
      final handoff = File('session-handoff.md').readAsStringSync();
      final init = File('init.sh').readAsStringSync();

      expect(progress, contains('Current State'));
      expect(progress, contains("What's Next"));
      expect(progress, contains('Evidence of Completion'));
      expect(progress, contains('Files Modified This Session'));

      expect(handoff, contains('Current Objective'));
      expect(handoff, contains('Verification Evidence'));
      expect(handoff, contains('Recommended Next Step'));

      expect(init, contains('set -e'));
      expect(init, contains('fvm dart run tool/harness.dart bootstrap'));
      expect(init, contains('fvm dart run tool/harness.dart check'));
    });

    test('ci runs the standard harness lifecycle', () {
      final workflow = File('.github/workflows/harness.yml').readAsStringSync();

      expect(workflow, contains('fvm install'));
      expect(workflow, contains('./init.sh'));
    });

    test('domain layer does not import data or presentation', () {
      final violations = _dartFilesUnder('lib/features')
          .where((file) => file.path.contains('/domain/'))
          .expand(_layerImportViolations)
          .toList();

      expect(violations, isEmpty);
    });

    test('data layer does not import presentation', () {
      final violations = _dartFilesUnder('lib/features')
          .where((file) => file.path.contains('/data/'))
          .expand(_presentationImportViolations)
          .toList();

      expect(violations, isEmpty);
    });

    test('features with domain or data expose all business layers', () {
      final featuresDirectory = Directory('lib/features');
      final featureDirectories = featuresDirectory
          .listSync()
          .whereType<Directory>()
          .where((directory) => !directory.path.endsWith('.DS_Store'));

      for (final feature in featureDirectories) {
        final hasBusinessLayer =
            Directory('${feature.path}/domain').existsSync() ||
            Directory('${feature.path}/data').existsSync();

        if (!hasBusinessLayer) {
          continue;
        }

        for (final layer in ['domain', 'data', 'presentation']) {
          final layerDirectory = Directory('${feature.path}/$layer');
          expect(
            layerDirectory.existsSync(),
            isTrue,
            reason: '${feature.path} should contain $layer',
          );
        }
      }
    });
  });
}

Iterable<File> _dartFilesUnder(String path) {
  return Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

Iterable<String> _layerImportViolations(File file) {
  final content = file.readAsStringSync();
  final forbiddenPatterns = [
    RegExp("import\\s+['\\\"].*/data/"),
    RegExp("import\\s+['\\\"].*/presentation/"),
    RegExp("import\\s+['\\\"]package:flutter_foundations/features/.*/data/"),
    RegExp(
      "import\\s+['\\\"]package:flutter_foundations/features/.*/presentation/",
    ),
  ];

  return forbiddenPatterns
      .where((pattern) => pattern.hasMatch(content))
      .map((pattern) => '${file.path} matches ${pattern.pattern}');
}

Iterable<String> _presentationImportViolations(File file) {
  final content = file.readAsStringSync();
  final forbiddenPatterns = [
    RegExp("import\\s+['\\\"].*/presentation/"),
    RegExp(
      "import\\s+['\\\"]package:flutter_foundations/features/.*/presentation/",
    ),
  ];

  return forbiddenPatterns
      .where((pattern) => pattern.hasMatch(content))
      .map((pattern) => '${file.path} matches ${pattern.pattern}');
}
