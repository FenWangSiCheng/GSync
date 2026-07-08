import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/directory_sync_bloc.dart';

class DirectorySyncPage extends StatelessWidget {
  const DirectorySyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'directory_sync_screen',
      label: 'Directory sync',
      container: true,
      child: Scaffold(
        appBar: AppBar(title: const Text('GitSync')),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        _Header(),
                        SizedBox(height: 20),
                        _DirectorySection(),
                        SizedBox(height: 16),
                        _RemoteSection(),
                        SizedBox(height: 16),
                        _SyncActionSection(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Directory sync', style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Choose one local directory and push its changes to a Git remote.',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _DirectorySection extends StatelessWidget {
  const _DirectorySection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorySyncBloc, DirectorySyncState>(
      buildWhen: (previous, current) {
        return previous.selectedDirectoryPath !=
                current.selectedDirectoryPath ||
            previous.status != current.status;
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              identifier: 'directory_picker_button',
              button: true,
              label: 'Choose directory',
              child: FilledButton.icon(
                key: const ValueKey('directory_picker_button'),
                onPressed: state.status == DirectorySyncStatus.syncing
                    ? null
                    : () => _showDirectoryPicker(context),
                icon: const Icon(Icons.folder_open),
                label: const Text('Choose directory'),
              ),
            ),
            const SizedBox(height: 10),
            Semantics(
              identifier: 'selected_directory_text',
              label: 'Selected directory',
              child: Text(
                state.selectedDirectoryPath.isEmpty
                    ? 'No directory selected'
                    : state.selectedDirectoryPath,
                key: const ValueKey('selected_directory_text'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDirectoryPicker(BuildContext context) async {
    final bloc = context.read<DirectorySyncBloc>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  identifier: 'directory_fixture_option',
                  button: true,
                  label: 'GitSync Fixture Notes',
                  child: ListTile(
                    key: const ValueKey('directory_fixture_option'),
                    leading: const Icon(Icons.folder_copy_outlined),
                    title: const Text('GitSync Fixture Notes'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      bloc.add(const DirectorySyncFixtureDirectorySelected());
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.drive_folder_upload_outlined),
                  title: const Text('System picker'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    bloc.add(const DirectorySyncSystemDirectoryRequested());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RemoteSection extends StatelessWidget {
  const _RemoteSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          identifier: 'remote_url_field',
          textField: true,
          label: 'Remote Git repository URL',
          child: TextField(
            key: const ValueKey('remote_url_field'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Remote Git repository URL',
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              context.read<DirectorySyncBloc>().add(
                DirectorySyncRemoteUrlChanged(value),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          identifier: 'auth_token_field',
          textField: true,
          label: 'Authentication token',
          child: TextField(
            key: const ValueKey('auth_token_field'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Authentication token',
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onChanged: (value) {
              context.read<DirectorySyncBloc>().add(
                DirectorySyncCredentialChanged(value),
              );
            },
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              identifier: 'sync_status_text',
              liveRegion: true,
              label: 'Sync status',
              child: Text(
                state.statusMessage,
                key: const ValueKey('sync_status_text'),
              ),
            ),
            if (state.status == DirectorySyncStatus.success) ...[
              const SizedBox(height: 8),
              Semantics(
                identifier: 'sync_success_text',
                liveRegion: true,
                label: 'Sync succeeded',
                child: const Text(
                  'Sync succeeded',
                  key: ValueKey('sync_success_text'),
                ),
              ),
            ],
            if (state.status == DirectorySyncStatus.failure) ...[
              const SizedBox(height: 8),
              Semantics(
                identifier: 'sync_error_text',
                liveRegion: true,
                label: 'Sync failed',
                child: const Text(
                  'Sync failed',
                  key: ValueKey('sync_error_text'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Semantics(
              identifier: 'sync_button',
              button: true,
              label: 'Sync',
              child: FilledButton.icon(
                key: const ValueKey('sync_button'),
                onPressed: state.canSync
                    ? () {
                        context.read<DirectorySyncBloc>().add(
                          const DirectorySyncRequested(),
                        );
                      }
                    : null,
                icon: state.status == DirectorySyncStatus.syncing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: const Text('Sync'),
              ),
            ),
          ],
        );
      },
    );
  }
}
