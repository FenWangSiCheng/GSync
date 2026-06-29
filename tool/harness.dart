import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;

Future<void> main(List<String> args) async {
  final command = args.isEmpty ? 'help' : args.first;
  final runner = HarnessRunner(stdout: stdout, stderr: stderr);

  late final int exitCode;
  switch (command) {
    case 'bootstrap':
      exitCode = await runner.bootstrap();
    case 'check':
      exitCode = await runner.check();
    case 'doctor':
      exitCode = await runner.doctor();
    case 'eval':
      exitCode = await runner.eval();
    case 'eval-android':
      exitCode = await runner.eval(platform: 'android');
    case 'eval-ios':
      exitCode = await runner.eval(platform: 'ios');
    case 'format':
      exitCode = await runner.formatCheck();
    case 'structure':
      exitCode = await runner.structure();
    case 'spec':
      exitCode = await runner.spec(args.sublist(1));
    case 'test':
      exitCode = await runner.test();
    case 'help':
    case '--help':
    case '-h':
      exitCode = runner.help();
    default:
      exitCode = runner.unknown(command);
  }

  exit(exitCode);
}

class HarnessRunner {
  HarnessRunner({required this.stdout, required this.stderr});

  final Stdout stdout;
  final IOSink stderr;

  int help() {
    stdout.writeln('Flutter Foundations harness');
    stdout.writeln('');
    stdout.writeln('Usage: fvm dart run tool/harness.dart <command>');
    stdout.writeln('');
    stdout.writeln('Commands:');
    stdout.writeln('  bootstrap  Install dependencies and regenerate code');
    stdout.writeln('  doctor     Print tool and repository diagnostics');
    stdout.writeln('  eval       Run optional Maestro E2E evaluation flows');
    stdout.writeln('  eval-android Run Android Maestro E2E evaluation flows');
    stdout.writeln('  eval-ios   Run iOS Maestro E2E evaluation flows');
    stdout.writeln('  format     Check formatting for lib, test, and tool');
    stdout.writeln('  structure  Run harness structural tests');
    stdout.writeln(
      '  spec       Spec workflow: new <id> | review <id> [--approve] | '
      'accept <id> [--maestro] [--platform ios|android]',
    );
    stdout.writeln('  test       Run the Flutter test suite');
    stdout.writeln('  check      Run format, structure, analyze, and tests');
    return 0;
  }

  int unknown(String command) {
    stderr.writeln('Unknown harness command: $command');
    help();
    return 64;
  }

  Future<int> bootstrap() async {
    return _runAll([
      CommandSpec('fvm', ['flutter', 'pub', 'get']),
      CommandSpec('fvm', [
        'flutter',
        'packages',
        'pub',
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ]),
    ]);
  }

  Future<int> check() async {
    return _runAll([
      CommandSpec('fvm', [
        'dart',
        'format',
        '--set-exit-if-changed',
        'lib',
        'test',
        'tool',
      ]),
      CommandSpec('fvm', ['dart', 'run', 'tool/harness.dart', 'structure']),
      CommandSpec('fvm', ['flutter', 'analyze']),
      CommandSpec('fvm', ['flutter', 'test']),
    ]);
  }

  Future<int> doctor() async {
    final diagnostics = <String, Object?>{
      'flutter': await _capture('fvm', ['flutter', '--version']),
      'fvm_dart': await _capture('fvm', ['dart', '--version']),
      'fvm': await _readJsonFile('.fvm/fvm_config.json'),
      'maestro': await _capture('maestro', ['--version']),
      'generated_files': _generatedFiles(),
      'harness_files': _requiredHarnessFiles()
          .map((path) => {'path': path, 'exists': File(path).existsSync()})
          .toList(),
      'harness_directories': _requiredHarnessDirectories()
          .map((path) => {'path': path, 'exists': Directory(path).existsSync()})
          .toList(),
      'agent_skills': _agentSkills(),
    };

    stdout.writeln(const JsonEncoder.withIndent('  ').convert(diagnostics));
    return 0;
  }

  Future<int> formatCheck() {
    return _runAll([
      CommandSpec('fvm', [
        'dart',
        'format',
        '--set-exit-if-changed',
        'lib',
        'test',
        'tool',
      ]),
    ]);
  }

  Future<int> eval({String? platform}) async {
    final maestro = await _capture('maestro', ['--version']);
    if (maestro['exit_code'] != 0) {
      stderr.writeln('Maestro CLI is not installed or not on PATH.');
      stderr.writeln('Install it with: brew tap mobile-dev-inc/tap');
      stderr.writeln('Then run: brew install mobile-dev-inc/tap/maestro');
      stderr.writeln('After launching a dev app on a simulator/device, run:');
      stderr.writeln('  fvm dart run tool/harness.dart eval');
      return 69;
    }

    final plat = platform ?? 'ios';
    final ready = await _deviceReady(plat);
    if (!ready.ready) {
      stderr.writeln('Device not ready for platform "$plat":');
      stderr.writeln(ready.reason);
      return 69;
    }

    final target = switch (plat) {
      'android' => '.maestro/android',
      'ios' => '.maestro/ios',
      _ => '.maestro',
    };

    return _runAll([
      CommandSpec('maestro', ['test', target]),
    ]);
  }

  Future<int> structure() {
    return _runAll([
      CommandSpec('fvm', ['flutter', 'test', 'test/harness']),
    ]);
  }

  /// Spec evaluation workflow.
  ///
  /// Four stages with two gates:
  ///   `spec new <id>`          AI scaffolds a reviewable acceptance script.
  ///   `spec review <id>`       Human reviews the acceptance checklist (gate A).
  ///       `--approve`          Mark the linked feature spec-approved.
  ///   `spec accept <id>`       AI runs acceptance and reports pass/fail (gate B).
  ///       `--maestro`          Also run device-backed Maestro criteria.
  ///       `--platform <p>`     Run Maestro on `ios` (default) or `android`.
  /// Gate B writes a report. If Maestro is requested but no booted device with
  /// the dev app installed is found, the report is marked BLOCKED.
  Future<int> spec(List<String> args) async {
    final sub = args.isEmpty ? 'help' : args.first;
    switch (sub) {
      case 'new':
        if (args.length < 2) {
          stderr.writeln('Usage: fvm dart run tool/harness.dart spec new <id>');
          return 64;
        }
        return _specNew(args[1]);
      case 'review':
        if (args.length < 2) {
          stderr.writeln(
            'Usage: fvm dart run tool/harness.dart spec review <id> [--approve]',
          );
          return 64;
        }
        return _specReview(args[1], approve: args.contains('--approve'));
      case 'accept':
        if (args.length < 2) {
          stderr.writeln(
            'Usage: fvm dart run tool/harness.dart spec accept <id> '
            '[--maestro] [--platform ios|android]',
          );
          return 64;
        }
        final platform = _platformArg(args);
        return _specAccept(
          args[1],
          platform: platform,
          runMaestro: args.contains('--maestro'),
        );
      case 'help':
      case '--help':
      case '-h':
        stdout.writeln('Spec workflow commands:');
        stdout.writeln(
          '  spec new <id>             Scaffold a reviewable spec',
        );
        stdout.writeln(
          '  spec review <id> [--approve]  Print the acceptance checklist (gate A)',
        );
        stdout.writeln(
          '  spec accept <id> [--maestro] [--platform ios|android]  Run acceptance and report (gate B)',
        );
        return 0;
      default:
        stderr.writeln('Unknown spec subcommand: $sub');
        return 64;
    }
  }

  String _platformArg(List<String> args) {
    final i = args.indexOf('--platform');
    if (i >= 0 && i + 1 < args.length) {
      final v = args[i + 1];
      if (v == 'ios' || v == 'android') return v;
    }
    return 'ios';
  }

  Future<int> _specNew(String id) async {
    final dir = Directory('docs/harness/specs/$id');
    if (dir.existsSync()) {
      stderr.writeln('Spec already exists: ${dir.path}');
      return 64;
    }
    final flow = _flowName(id);
    await dir.create(recursive: true);
    await File('${dir.path}/spec.md').writeAsString(_specMarkdownTemplate(id));
    await File(
      '${dir.path}/ui-map.delta.yaml',
    ).writeAsString(_uiMapDeltaTemplate(id));
    await File(
      '${dir.path}/acceptance.yaml',
    ).writeAsString(_acceptanceTemplate(id, flow));
    await File(
      '.maestro/ios/$flow.yaml',
    ).writeAsString(_maestroFlowTemplate('cn.com.fenrir-inc.iosAppTest.dev'));
    await File(
      '.maestro/android/$flow.yaml',
    ).writeAsString(_maestroFlowTemplate('com.example.basic_demo.dev'));
    stdout.writeln('Scaffolded spec "$id" at ${dir.path}');
    stdout.writeln(
      'Scaffolded Maestro flows: .maestro/ios/$flow.yaml, '
      '.maestro/android/$flow.yaml',
    );
    stdout.writeln('');
    stdout.writeln('Next steps:');
    stdout.writeln('  1. Fill spec.md with goal, preconditions, and steps.');
    stdout.writeln('  2. Add only new UI targets to ui-map.delta.yaml.');
    stdout.writeln(
      '  3. Map UI criteria to Maestro flows; use test files only for non-UI logic.',
    );
    stdout.writeln(
      '  4. Translate the spec steps into the Maestro flow files.',
    );
    stdout.writeln('  5. fvm dart run tool/harness.dart spec review $id');
    return 0;
  }

  String _flowName(String id) => '${id.replaceAll('-', '_')}_flow';

  String _maestroFlowTemplate(String appId) =>
      '''
appId: $appId
---
- launchApp
# Translate spec steps here. Prefer semantics_identifier ids from ui-map.yaml.
''';

  Future<int> _specReview(String id, {required bool approve}) async {
    final file = _acceptanceFile(id);
    if (file == null) {
      stderr.writeln('No acceptance.yaml found for spec "$id".');
      stderr.writeln(
        'Expected docs/harness/specs/$id/acceptance.yaml '
        'or docs/harness/specs/acceptance.yaml with spec: $id.',
      );
      return 64;
    }
    final doc = yaml.loadYaml(file.readAsStringSync()) as yaml.YamlMap;
    final acceptance = doc['acceptance'] as yaml.YamlList;
    final status = _specStatus(id);

    stdout.writeln('Spec: $id');
    if (doc['feature'] != null) {
      stdout.writeln('Feature: ${doc['feature']}  (status: $status)');
    }
    if (doc['goal'] != null) {
      stdout.writeln('Goal: ${doc['goal']}');
    }
    stdout.writeln('');
    stdout.writeln('Acceptance checklist (gate A):');
    for (final item in acceptance) {
      final m = item as yaml.YamlMap;
      stdout.writeln('  [${m['kind']}] ${m['id']}  ${m['claim']}');
    }
    stdout.writeln('');
    if (approve) {
      final updated = _setSpecStatus(id, 'spec-approved');
      if (updated) {
        stdout.writeln(
          'Marked spec "$id" as spec-approved in feature_list.json.',
        );
        stdout.writeln('Implementation may now proceed.');
      } else {
        stderr.writeln(
          'Could not find a feature linked to spec "$id" in feature_list.json.',
        );
        return 64;
      }
    } else {
      stdout.writeln('Review the checklist. To approve, run:');
      stdout.writeln(
        '  fvm dart run tool/harness.dart spec review $id --approve',
      );
    }
    return 0;
  }

  Future<int> _specAccept(
    String id, {
    required String platform,
    required bool runMaestro,
  }) async {
    final file = _acceptanceFile(id);
    if (file == null) {
      stderr.writeln('No acceptance.yaml found for spec "$id".');
      return 64;
    }
    final doc = yaml.loadYaml(file.readAsStringSync()) as yaml.YamlMap;
    final acceptance = doc['acceptance'] as yaml.YamlList;

    final testFiles = <String>{};
    final maestroFlows = <String>{};
    for (final item in acceptance) {
      final m = item as yaml.YamlMap;
      final kind = m['kind'].toString();
      if (kind == 'test') {
        testFiles.add(m['file'].toString());
      } else if (kind == 'maestro') {
        maestroFlows.add((m['flow'] ?? _flowName(id)).toString());
      }
    }

    // Run non-UI unit or logic tests first.
    final testRan = testFiles.isNotEmpty;
    var testExit = 0;
    if (testRan) {
      stdout.writeln(
        '> running ${testFiles.length} test file(s) for spec "$id"',
      );
      testExit = await _run(
        CommandSpec('fvm', ['flutter', 'test', ...testFiles]),
      );
    }

    var maestroBlockedReason = '';
    final flowResults = <String, int>{};
    if (runMaestro) {
      if (maestroFlows.isEmpty) {
        maestroBlockedReason =
            'Spec "$id" has no kind: maestro acceptance criteria.';
      } else {
        final maestroOk = await _capture('maestro', ['--version']);
        if (maestroOk['exit_code'] != 0) {
          maestroBlockedReason =
              'Maestro CLI is not installed or not on PATH. Install it with: '
              'brew tap mobile-dev-inc/tap && brew install mobile-dev-inc/tap/maestro';
        }
      }

      if (maestroBlockedReason.isEmpty) {
        final ready = await _deviceReady(platform);
        if (!ready.ready) {
          maestroBlockedReason = ready.reason;
        }
      }

      if (maestroBlockedReason.isEmpty) {
        final missing = maestroFlows
            .map((flow) => '.maestro/$platform/$flow.yaml')
            .where((path) => !File(path).existsSync())
            .toList();
        if (missing.isNotEmpty) {
          maestroBlockedReason =
              'Missing Maestro flow file(s) for platform "$platform": '
              '${missing.join(', ')}';
        }
      }

      if (maestroBlockedReason.isEmpty) {
        for (final flow in maestroFlows) {
          final path = '.maestro/$platform/$flow.yaml';
          stdout.writeln('> running maestro flow $path');
          flowResults[flow] = await _run(
            CommandSpec('maestro', ['test', path]),
          );
        }
      } else {
        stderr.writeln('Maestro acceptance blocked for platform "$platform":');
        stderr.writeln(maestroBlockedReason);
      }
    }
    final maestroAllPass =
        runMaestro &&
        maestroBlockedReason.isEmpty &&
        flowResults.values.every((e) => e == 0);

    final results = <Map<String, Object?>>[];
    for (final item in acceptance) {
      final m = item as yaml.YamlMap;
      final kind = m['kind'].toString();
      String verdict;
      String evidence;
      if (kind == 'test') {
        verdict = testRan && testExit == 0 ? 'pass' : 'fail';
        evidence = m['file'].toString();
      } else if (kind == 'maestro') {
        final flow = (m['flow'] ?? _flowName(id)).toString();
        if (!runMaestro) {
          verdict = 'skipped';
        } else if (maestroBlockedReason.isNotEmpty) {
          verdict = 'blocked';
        } else {
          verdict = flowResults[flow] == 0 ? 'pass' : 'fail';
        }
        evidence = '.maestro/$platform/$flow.yaml';
      } else {
        verdict = 'blocked';
        evidence = 'unknown kind $kind';
      }
      results.add({
        'id': m['id'].toString(),
        'claim': m['claim'].toString(),
        'kind': kind,
        'verdict': verdict,
        'evidence': evidence,
      });
    }

    final hasFail = results.any((r) => r['verdict'] == 'fail');
    final hasBlocked = results.any((r) => r['verdict'] == 'blocked');
    final hasPass = results.any((r) => r['verdict'] == 'pass');
    final overall = hasFail
        ? 'FAIL'
        : hasBlocked
        ? 'BLOCKED'
        : hasPass
        ? 'PASS'
        : 'SKIPPED';

    final report = <String, Object?>{
      'spec': id,
      'feature': doc['feature']?.toString(),
      'platform': platform,
      'result': overall,
      'maestro_run': runMaestro && maestroBlockedReason.isEmpty,
      'maestro_blocked_reason': maestroBlockedReason.isEmpty
          ? null
          : maestroBlockedReason,
      'maestro_all_pass': maestroAllPass,
      'acceptance': results,
    };
    final evidenceDir = Directory('build/harness/evidence/$id');
    await evidenceDir.create(recursive: true);
    await File(
      '${evidenceDir.path}/report.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));

    stdout.writeln('');
    stdout.writeln('Acceptance report for "$id": $overall');
    for (final r in results) {
      stdout.writeln('  [${r['verdict']}] ${r['id']}  ${r['claim']}');
    }
    stdout.writeln('Evidence: ${evidenceDir.path}/report.json');
    return overall == 'PASS' ? 0 : 1;
  }

  /// Detect whether a booted device for [platform] is ready and the dev app
  /// is installed. Reads the app id from the first Maestro flow file found
  /// under `.maestro/<platform>/` so the check stays in sync with the flows.
  Future<_DeviceReadiness> _deviceReady(String platform) async {
    final appId = _flowAppId(platform);
    if (platform == 'ios') {
      final booted = await _capture('xcrun', [
        'simctl',
        'list',
        'devices',
        'booted',
      ]);
      final bootedOk =
          booted['exit_code'] == 0 &&
          (booted['stdout'] as String).contains('Booted');
      if (!bootedOk) {
        return _DeviceReadiness(
          ready: false,
          reason:
              'No booted iOS simulator. Boot one with '
              '`xcrun simctl boot "iPhone 16 Pro"` then open the Simulator '
              'app, or run via `--platform android`.',
        );
      }
      if (appId == null) {
        return _DeviceReadiness(
          ready: false,
          reason:
              'No Maestro flow found under .maestro/ios/ to read the '
              'appId from. Run `spec new <id>` or add a flow file.',
        );
      }
      final installed = await _capture('xcrun', [
        'simctl',
        'get_app_container',
        'booted',
        appId,
      ]);
      if (installed['exit_code'] != 0) {
        return _DeviceReadiness(
          ready: false,
          reason:
              'Dev app "$appId" is not installed on the booted simulator. '
              'Install it with:\n'
              '  fvm flutter run -d <udid> --flavor dev '
              '--dart-define-from-file=dart_defines/dev.json\n'
              '(quit once installed; Maestro launches it itself).',
        );
      }
      return _DeviceReadiness(ready: true, reason: '');
    }

    // android
    final devices = await _capture('adb', ['devices']);
    final deviceOk =
        devices['exit_code'] == 0 &&
        (devices['stdout'] as String).contains(RegExp(r'device\s*$'));
    if (!deviceOk) {
      return _DeviceReadiness(
        ready: false,
        reason:
            'No Android device/emulator connected via adb. Start an '
            'emulator or connect a device, or run via `--platform ios`.',
      );
    }
    if (appId == null) {
      return _DeviceReadiness(
        ready: false,
        reason:
            'No Maestro flow found under .maestro/android/ to read the '
            'appId from. Run `spec new <id>` or add a flow file.',
      );
    }
    final installed = await _capture('adb', ['shell', 'pm', 'path', appId]);
    if (installed['exit_code'] != 0 ||
        (installed['stdout'] as String).isEmpty) {
      return _DeviceReadiness(
        ready: false,
        reason:
            'Dev app "$appId" is not installed on the Android device. '
            'Install it with:\n'
            '  fvm flutter run --flavor dev '
            '--dart-define-from-file=dart_defines/dev.json\n'
            '(quit once installed; Maestro launches it itself).',
      );
    }
    return _DeviceReadiness(ready: true, reason: '');
  }

  /// Read the `appId:` from the first `.maestro/<platform>/*.yaml` file.
  String? _flowAppId(String platform) {
    final dir = Directory('.maestro/$platform');
    if (!dir.existsSync()) return null;
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml'))
        .toList();
    if (files.isEmpty) return null;
    try {
      final doc = yaml.loadYaml(files.first.readAsStringSync());
      if (doc is yaml.YamlMap) {
        return doc['appId']?.toString();
      }
    } on Object {
      // fall through; some flow files use a multi-document YAML with appId as
      // a bare leading scalar. Parse the first line defensively.
    }
    for (final line in files.first.readAsLinesSync()) {
      final m = RegExp(r'^appId:\s*(.+)$').firstMatch(line);
      if (m != null) return m.group(1)!.trim();
    }
    return null;
  }

  File? _acceptanceFile(String id) {
    final nested = File('docs/harness/specs/$id/acceptance.yaml');
    if (nested.existsSync()) return nested;
    final flat = File('docs/harness/specs/acceptance.yaml');
    if (flat.existsSync()) {
      final doc = yaml.loadYaml(flat.readAsStringSync());
      if (doc is yaml.YamlMap && doc['spec'] == id) return flat;
    }
    return null;
  }

  String _specStatus(String id) {
    final features = _loadFeatures();
    for (final feature in features) {
      if (feature['spec'] == id) {
        return feature['status']?.toString() ?? 'unknown';
      }
    }
    return 'unlinked';
  }

  bool _setSpecStatus(String id, String status) {
    final raw = File('feature_list.json').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    final features = (decoded['features'] as List<Object?>)
        .cast<Map<String, Object?>>();
    var found = false;
    for (final feature in features) {
      if (feature['spec'] == id) {
        feature['status'] = status;
        found = true;
      }
    }
    if (!found) return false;
    File(
      'feature_list.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(decoded));
    return true;
  }

  List<Map<String, Object?>> _loadFeatures() {
    final raw = File('feature_list.json').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    return (decoded['features'] as List<Object?>).cast<Map<String, Object?>>();
  }

  String _specMarkdownTemplate(String id) =>
      '''
# Spec: $id

## Goal

Describe what this spec verifies.

## Preconditions

- Run the `dev` flavor.

## Steps

1. Launch the app.
2. ...

## Acceptance Criteria

Mirrored as machine-checkable items in `acceptance.yaml`.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
''';

  String _uiMapDeltaTemplate(String id) =>
      '''
# New UI targets introduced by the "$id" spec.
# These merge into docs/harness/specs/ui-map.yaml once approved.
targets: {}
''';

  String _acceptanceTemplate(String id, String flow) =>
      '''
spec: $id
feature: feat-XXX
goal: 'Describe what this spec verifies.'
preconditions:
  - Run the dev flavor.
acceptance:
  - id: a1
    claim: 'Describe the E2E outcome verified by the Maestro flow.'
    kind: maestro
    flow: $flow
# Add kind: test criteria only for non-UI logic, data, BLoC, repository, or
# harness unit tests. UI behavior belongs in the Maestro flow above.
''';

  Future<int> test() {
    return _runAll([
      CommandSpec('fvm', ['flutter', 'test']),
    ]);
  }

  Future<int> _runAll(List<CommandSpec> commands) async {
    for (final command in commands) {
      final result = await _run(command);
      if (result != 0) {
        return result;
      }
    }
    return 0;
  }

  Future<int> _run(CommandSpec command) async {
    stdout.writeln('> ${command.executable} ${command.arguments.join(' ')}');
    final process = await Process.start(
      command.executable,
      command.arguments,
      mode: ProcessStartMode.inheritStdio,
    );
    return process.exitCode;
  }

  Future<Map<String, Object?>> _capture(
    String executable,
    List<String> arguments,
  ) async {
    final command = '$executable ${arguments.join(' ')}';

    // Try to find adb in common Android SDK locations if not on PATH
    final env = <String, String>{};
    if (executable == 'adb') {
      final candidatePaths = <String>[
        if (Platform.environment.containsKey('ANDROID_HOME'))
          '${Platform.environment['ANDROID_HOME']}/platform-tools',
        if (Platform.environment.containsKey('ANDROID_SDK_ROOT'))
          '${Platform.environment['ANDROID_SDK_ROOT']}/platform-tools',
        '${Platform.environment['HOME']}/Library/Android/sdk/platform-tools',
        '${Platform.environment['HOME']}/Android/Sdk/platform-tools',
        '/usr/local/share/android-sdk/platform-tools',
        '/opt/android-sdk/platform-tools',
      ];

      for (final path in candidatePaths) {
        final adbPath = '$path/adb';
        if (File(adbPath).existsSync()) {
          env['PATH'] = '${Platform.environment['PATH']}:$path';
          break;
        }
      }
    }

    try {
      final result = await Process.run(
        executable,
        arguments,
        environment: env.isEmpty ? null : env,
      );
      return {
        'command': command,
        'exit_code': result.exitCode,
        'stdout': result.stdout.toString().trim(),
        'stderr': result.stderr.toString().trim(),
      };
    } on ProcessException catch (error) {
      return {
        'command': command,
        'exit_code': 127,
        'stdout': '',
        'stderr': error.message,
      };
    }
  }

  Future<Object?> _readJsonFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      return {'missing': path};
    }
    return jsonDecode(await file.readAsString());
  }

  List<Map<String, Object?>> _generatedFiles() {
    const files = [
      'lib/core/injection/injection.config.dart',
      'lib/features/user/data/models/user_model.freezed.dart',
      'lib/features/user/data/models/user_model.g.dart',
    ];

    return files.map((path) {
      return {'path': path, 'exists': File(path).existsSync()};
    }).toList();
  }

  List<String> _requiredHarnessFiles() {
    return const [
      'AGENTS.md',
      'feature_list.json',
      'progress.md',
      'init.sh',
      'session-handoff.md',
      '.github/workflows/harness.yml',
      'docs/harness/README.md',
      'docs/harness/ARCHITECTURE.md',
      'docs/harness/VALIDATION.md',
      'docs/harness/SKILLS.md',
      'docs/harness/QUALITY.md',
      'docs/harness/OPERABILITY.md',
      'docs/harness/TASKS.md',
      'tool/harness.dart',
    ];
  }

  List<String> _requiredHarnessDirectories() {
    return const ['.agents/skills'];
  }

  List<Map<String, Object?>> _agentSkills() {
    final directory = Directory('.agents/skills');
    if (!directory.existsSync()) {
      return const [];
    }

    return directory.listSync().whereType<Directory>().map((skill) {
        final name = skill.uri.pathSegments
            .where((segment) => segment.isNotEmpty)
            .last;
        return {
          'name': name,
          'skill_file': '${skill.path}/SKILL.md',
          'exists': File('${skill.path}/SKILL.md').existsSync(),
        };
      }).toList()
      ..sort((a, b) => (a['name']! as String).compareTo(b['name']! as String));
  }
}

class CommandSpec {
  const CommandSpec(this.executable, this.arguments);

  final String executable;
  final List<String> arguments;
}

class _DeviceReadiness {
  const _DeviceReadiness({required this.ready, required this.reason});

  final bool ready;
  final String reason;
}
