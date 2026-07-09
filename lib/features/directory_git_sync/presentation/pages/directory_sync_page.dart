import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/router_constants.dart';
import '../../../../core/widgets/cupertino_text_field_menu.dart';
import '../bloc/directory_sync_bloc.dart';
import '../models/selected_directory_display.dart';

class DirectorySyncPage extends StatelessWidget {
  const DirectorySyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'directory_sync_screen',
      label: '目录同步',
      container: true,
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('GitSync'),
              backgroundColor: CupertinoColors.systemGroupedBackground,
              trailing: Semantics(
                identifier: 'token_settings_button',
                button: true,
                label: 'GitHub 授权设置',
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    await context.push(RouterPaths.tokenSettings);
                    if (context.mounted) {
                      context.read<DirectorySyncBloc>().add(
                        const DirectorySyncTokenStatusRequested(),
                      );
                    }
                  },
                  child: const Icon(CupertinoIcons.lock_shield),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(),
                        SizedBox(height: 20),
                        _DirectorySection(),
                        SizedBox(height: 12),
                        _TokenSection(),
                        SizedBox(height: 12),
                        _RemoteSection(),
                        SizedBox(height: 16),
                        _SyncActionSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '目录同步',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '选择一个本地目录,将 GitHub 远程仓库内容同步到这里。',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectorySection extends StatelessWidget {
  const _DirectorySection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorySyncBloc, DirectorySyncState>(
      buildWhen: (previous, current) =>
          previous.selectedDirectoryPath != current.selectedDirectoryPath ||
          previous.status != current.status,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Semantics(
                identifier: 'directory_picker_button',
                button: true,
                label: '选择目录',
                child: CupertinoButton.filled(
                  onPressed: state.status == DirectorySyncStatus.syncing
                      ? null
                      : () => context.read<DirectorySyncBloc>().add(
                          const DirectorySyncSystemDirectoryRequested(),
                        ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.folder_open),
                      SizedBox(width: 6),
                      Text('更改目录'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CupertinoListSection.insetGrouped(
              header: const Text('已选目录'),
              topMargin: 0,
              hasLeading: false,
              children: [
                CupertinoListTile.notched(
                  title: Semantics(
                    identifier: 'selected_directory_text',
                    label: '已选目录',
                    child: _SelectedDirectoryText(
                      path: state.selectedDirectoryPath,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SelectedDirectoryText extends StatelessWidget {
  const _SelectedDirectoryText({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final display = SelectedDirectoryDisplay.fromPath(path);
    if (!display.hasDirectory) {
      return Text(
        display.name,
        style: const TextStyle(color: CupertinoColors.placeholderText),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          display.name,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          display.detail,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            height: 1.3,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
      ],
    );
  }
}

class _TokenSection extends StatelessWidget {
  const _TokenSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorySyncBloc, DirectorySyncState>(
      buildWhen: (previous, current) =>
          previous.hasCredential != current.hasCredential,
      builder: (context, state) {
        return CupertinoListSection.insetGrouped(
          header: const Text('GitHub 授权'),
          topMargin: 0,
          hasLeading: false,
          children: [
            CupertinoListTile.notched(
              title: Semantics(
                identifier: 'directory_token_status_text',
                label: '目录同步 GitHub 授权状态',
                child: Text(
                  state.hasCredential ? '已完成 GitHub 授权' : '未完成 GitHub 授权',
                  style: TextStyle(
                    color: state.hasCredential
                        ? CupertinoColors.activeGreen
                        : CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  await context.push(RouterPaths.tokenSettings);
                  if (context.mounted) {
                    context.read<DirectorySyncBloc>().add(
                      const DirectorySyncTokenStatusRequested(),
                    );
                  }
                },
                child: const Text('设置'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RemoteSection extends StatelessWidget {
  const _RemoteSection();

  @override
  Widget build(BuildContext context) {
    return CupertinoFormSection.insetGrouped(
      header: const Text('远程仓库来源'),
      children: [
        CupertinoFormRow(
          prefix: const Text('地址'),
          child: Semantics(
            identifier: 'remote_url_field',
            textField: true,
            label: 'GitHub 仓库或目录地址',
            child: CupertinoTextField(
              placeholder: 'GitHub 仓库或目录地址',
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              enableInteractiveSelection: true,
              contextMenuBuilder: cupertinoTextFieldContextMenu,
              onChanged: (value) {
                context.read<DirectorySyncBloc>().add(
                  DirectorySyncRemoteUrlChanged(value),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SyncActionSection extends StatelessWidget {
  const _SyncActionSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorySyncBloc, DirectorySyncState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                identifier: 'sync_status_text',
                liveRegion: true,
                label: '同步状态',
                child: Text(
                  state.statusMessage,
                  key: const ValueKey('sync_status_text'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
              if (state.status == DirectorySyncStatus.syncing) ...[
                const SizedBox(height: 10),
                Semantics(
                  identifier: 'sync_progress_indicator',
                  label: '同步进度',
                  child: const LinearProgressIndicator(
                    minHeight: 3,
                    color: CupertinoColors.activeBlue,
                    backgroundColor: CupertinoColors.systemGrey5,
                  ),
                ),
              ],
              if (state.status == DirectorySyncStatus.success) ...[
                const SizedBox(height: 8),
                Semantics(
                  identifier: 'sync_success_text',
                  liveRegion: true,
                  label: '同步成功',
                  child: Text(
                    '同步成功',
                    key: ValueKey('sync_success_text'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.activeGreen,
                    ),
                  ),
                ),
              ],
              if (state.status == DirectorySyncStatus.failure) ...[
                const SizedBox(height: 8),
                Semantics(
                  identifier: 'sync_error_text',
                  liveRegion: true,
                  label: '同步失败',
                  child: Text(
                    '同步失败',
                    key: ValueKey('sync_error_text'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Semantics(
                identifier: 'sync_button',
                button: true,
                label: '同步',
                child: CupertinoButton.filled(
                  onPressed: state.canSync
                      ? () {
                          context.read<DirectorySyncBloc>().add(
                            const DirectorySyncRequested(),
                          );
                        }
                      : null,
                  child: state.status == DirectorySyncStatus.syncing
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.arrow_2_circlepath),
                            SizedBox(width: 6),
                            Text('同步'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
