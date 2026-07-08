import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/token_settings_bloc.dart';

class TokenSettingsPage extends StatelessWidget {
  const TokenSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'token_settings_screen',
      label: '令牌设置',
      container: true,
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          leading: Semantics(
            identifier: 'token_settings_back_button',
            button: true,
            label: '返回',
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.pop(),
              child: const Icon(CupertinoIcons.back),
            ),
          ),
          middle: const Text('令牌设置'),
          backgroundColor: CupertinoColors.systemGroupedBackground,
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: const _TokenSettingsContent(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TokenSettingsContent extends StatelessWidget {
  const _TokenSettingsContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TokenSettingsBloc, TokenSettingsState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('当前状态'),
              topMargin: 0,
              hasLeading: false,
              children: [
                CupertinoListTile.notched(
                  title: Semantics(
                    identifier: 'saved_token_status_text',
                    liveRegion: true,
                    label: '令牌状态',
                    child: Text(
                      state.hasToken ? '已保存访问令牌' : '未保存访问令牌',
                      style: TextStyle(
                        color: state.hasToken
                            ? CupertinoColors.activeGreen
                            : CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: const Text('访问令牌'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('令牌'),
                  child: Semantics(
                    identifier: 'token_input_field',
                    textField: true,
                    label: '新的访问令牌',
                    child: CupertinoTextField(
                      placeholder: '新的访问令牌',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      enableInteractiveSelection: true,
                      contextMenuBuilder: _cupertinoTextFieldContextMenu,
                      onChanged: (value) {
                        context.read<TokenSettingsBloc>().add(
                          TokenSettingsTokenChanged(value),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Semantics(
                identifier: 'token_settings_status_text',
                liveRegion: true,
                label: '令牌设置状态',
                child: Text(
                  state.statusMessage,
                  style: const TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Semantics(
                identifier: 'save_token_button',
                button: true,
                label: '保存令牌',
                child: CupertinoButton.filled(
                  onPressed: state.canSave
                      ? () {
                          context.read<TokenSettingsBloc>().add(
                            const TokenSettingsSaveRequested(),
                          );
                        }
                      : null,
                  child: state.status == TokenSettingsStatus.saving
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.lock_shield),
                            SizedBox(width: 6),
                            Text('保存令牌'),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Semantics(
                identifier: 'delete_token_button',
                button: true,
                label: '删除令牌',
                child: CupertinoButton(
                  onPressed: state.canDelete
                      ? () {
                          context.read<TokenSettingsBloc>().add(
                            const TokenSettingsDeleteRequested(),
                          );
                        }
                      : null,
                  color: CupertinoColors.systemGrey5,
                  child: const Text('删除令牌'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

Widget _cupertinoTextFieldContextMenu(
  BuildContext context,
  EditableTextState editableTextState,
) {
  return CupertinoAdaptiveTextSelectionToolbar.editableText(
    editableTextState: editableTextState,
  );
}
