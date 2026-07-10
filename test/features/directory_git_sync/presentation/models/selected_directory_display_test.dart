import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foundations/features/directory_git_sync/presentation/models/selected_directory_display.dart';

void main() {
  group('SelectedDirectoryDisplay', () {
    test('shows placeholder when no directory is selected', () {
      final display = SelectedDirectoryDisplay.fromPath(' ');

      expect(display.hasDirectory, isFalse);
      expect(display.name, '未选择目录');
      expect(display.detail, isEmpty);
    });

    test('hides iOS file provider sandbox path behind a user-facing detail', () {
      const path =
          '/Users/me/Library/Developer/CoreSimulator/Devices/device/data/'
          'Containers/Shared/AppGroup/group/File Provider Storage/Investments';

      final display = SelectedDirectoryDisplay.fromPath(path);

      expect(display.hasDirectory, isTrue);
      expect(display.name, 'Investments');
      expect(display.detail, '我的 iPhone 中的文件夹');
    });

    test(
      'hides app documents sandbox path behind a default directory detail',
      () {
        const path =
            '/Users/me/Library/Developer/CoreSimulator/Devices/device/data/'
            'Containers/Data/Application/app/Documents/GitSync';

        final display = SelectedDirectoryDisplay.fromPath(path);

        expect(display.name, 'GitSync');
        expect(display.detail, '应用默认同步目录');
      },
    );

    test('keeps ordinary paths visible', () {
      const path = '/storage/emulated/0/Documents/Investments';

      final display = SelectedDirectoryDisplay.fromPath(path);

      expect(display.name, 'Investments');
      expect(display.detail, path);
    });
  });
}
