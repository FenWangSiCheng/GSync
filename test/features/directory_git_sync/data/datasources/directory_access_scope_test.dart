import 'package:flutter/services.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/datasources/directory_access_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlatformDirectoryAccessScope', () {
    const channel = MethodChannel('test.gsync/directory_access');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('wraps iOS work in security-scoped directory access', () async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            expect(call.arguments, <String, Object?>{'path': '/Files/Notes'});
            return call.method == 'startAccessingDirectory';
          });

      final result =
          await const PlatformDirectoryAccessScope(
            isIOS: true,
            channel: channel,
          ).runWithWriteAccess(
            directoryPath: '/Files/Notes',
            action: () async {
              calls.add('action');
              return 42;
            },
          );

      expect(result, 42);
      expect(calls, <String>[
        'startAccessingDirectory',
        'action',
        'stopAccessingDirectory',
      ]);
    });

    test('stops iOS directory access when the action fails', () async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            return call.method == 'startAccessingDirectory';
          });

      await expectLater(
        () => const PlatformDirectoryAccessScope(isIOS: true, channel: channel)
            .runWithWriteAccess<void>(
              directoryPath: '/Files/Notes',
              action: () async {
                calls.add('action');
                throw Exception('write failed');
              },
            ),
        throwsException,
      );

      expect(calls, <String>[
        'startAccessingDirectory',
        'action',
        'stopAccessingDirectory',
      ]);
    });

    test('does not call the platform channel outside iOS', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            fail('Non-iOS platforms should not invoke the directory channel.');
          });

      final result =
          await const PlatformDirectoryAccessScope(
            isIOS: false,
            channel: channel,
          ).runWithWriteAccess(
            directoryPath: '/Files/Notes',
            action: () async => 'ok',
          );

      expect(result, 'ok');
    });
  });
}
