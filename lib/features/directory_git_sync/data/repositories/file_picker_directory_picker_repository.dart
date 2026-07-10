// coverage:ignore-file

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../../domain/repositories/directory_picker_repository.dart';

class FilePickerDirectoryPickerRepository implements DirectoryPickerRepository {
  const FilePickerDirectoryPickerRepository();

  static const MethodChannel _iosDirectoryChannel = MethodChannel(
    'cn.com.fenrir_inc.gsync/directory_access',
  );

  @override
  Future<String?> pickDirectory() {
    if (Platform.isIOS) {
      return _iosDirectoryChannel.invokeMethod<String>('pickDirectory');
    }
    return FilePicker.getDirectoryPath(dialogTitle: '选择要同步的目录');
  }
}
