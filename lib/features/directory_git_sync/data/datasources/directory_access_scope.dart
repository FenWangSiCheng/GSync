import 'dart:io';

import 'package:flutter/services.dart';

abstract class DirectoryAccessScope {
  Future<T> runWithWriteAccess<T>({
    required String directoryPath,
    required Future<T> Function() action,
  });
}

class NoopDirectoryAccessScope implements DirectoryAccessScope {
  const NoopDirectoryAccessScope();

  @override
  Future<T> runWithWriteAccess<T>({
    required String directoryPath,
    required Future<T> Function() action,
  }) {
    return action();
  }
}

class PlatformDirectoryAccessScope implements DirectoryAccessScope {
  const PlatformDirectoryAccessScope({
    bool? isIOS,
    MethodChannel channel = _defaultChannel,
  }) : _isIOS = isIOS,
       _channel = channel;

  static const MethodChannel _defaultChannel = MethodChannel(
    'cn.com.fenrir_inc.gsync/directory_access',
  );

  final bool? _isIOS;
  final MethodChannel _channel;

  @override
  Future<T> runWithWriteAccess<T>({
    required String directoryPath,
    required Future<T> Function() action,
  }) async {
    if (!(_isIOS ?? Platform.isIOS)) {
      return action();
    }

    final didStart = await _channel.invokeMethod<bool>(
      'startAccessingDirectory',
      <String, Object?>{'path': directoryPath},
    );
    try {
      return await action();
    } finally {
      if (didStart ?? false) {
        await _channel.invokeMethod<void>(
          'stopAccessingDirectory',
          <String, Object?>{'path': directoryPath},
        );
      }
    }
  }
}
