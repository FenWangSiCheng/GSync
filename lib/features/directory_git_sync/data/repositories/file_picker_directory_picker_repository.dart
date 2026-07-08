// coverage:ignore-file

import 'package:file_picker/file_picker.dart';

import '../../domain/repositories/directory_picker_repository.dart';

class FilePickerDirectoryPickerRepository implements DirectoryPickerRepository {
  const FilePickerDirectoryPickerRepository();

  @override
  Future<String?> pickDirectory() {
    return FilePicker.getDirectoryPath(
      dialogTitle: 'Choose a directory to sync',
    );
  }
}
