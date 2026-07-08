import '../repositories/directory_picker_repository.dart';

class PickSyncDirectory {
  const PickSyncDirectory(this._repository);

  final DirectoryPickerRepository _repository;

  Future<String?> call() => _repository.pickDirectory();
}
