import 'package:path/path.dart' as p;

class SelectedDirectoryDisplay {
  const SelectedDirectoryDisplay({
    required this.name,
    required this.detail,
    required this.hasDirectory,
  });

  factory SelectedDirectoryDisplay.fromPath(String path) {
    final trimmedPath = path.trim();
    if (trimmedPath.isEmpty) {
      return const SelectedDirectoryDisplay(
        name: '未选择目录',
        detail: '',
        hasDirectory: false,
      );
    }

    return SelectedDirectoryDisplay(
      name: p.basename(trimmedPath),
      detail: _friendlyDirectoryDetail(trimmedPath),
      hasDirectory: true,
    );
  }

  final String name;
  final String detail;
  final bool hasDirectory;
}

String _friendlyDirectoryDetail(String path) {
  final normalizedPath = path.replaceAll(r'\', '/');
  if (_isIosFileProviderPath(normalizedPath)) {
    return '我的 iPhone 中的文件夹';
  }
  if (_isIosAppDocumentsPath(normalizedPath)) {
    return '应用默认同步目录';
  }
  return path;
}

bool _isIosFileProviderPath(String path) {
  return path.contains('/File Provider Storage/') ||
      path.contains('/Containers/Shared/AppGroup/');
}

bool _isIosAppDocumentsPath(String path) {
  return path.contains('/Containers/Data/Application/') &&
      path.contains('/Documents/');
}
