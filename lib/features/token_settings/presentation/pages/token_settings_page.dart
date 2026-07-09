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
          middle: const Text('GitHub 授权'),
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
                    label: 'GitHub 授权状态',
                    child: Text(
                      state.hasToken ? '已完成 GitHub 授权' : '未完成 GitHub 授权',
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
            CupertinoListSection.insetGrouped(
              header: const Text('设备码授权'),
              footer: const Text('前往 GitHub 设备授权页面输入代码。应用会自动等待授权完成并安全保存访问令牌。'),
              hasLeading: false,
              children: [
                CupertinoListTile.notched(
                  title: const Text('授权地址'),
                  subtitle: Semantics(
                    identifier: 'device_flow_verification_url_text',
                    liveRegion: true,
                    label: 'GitHub 设备授权地址',
                    child: Text(
                      state.verificationUri.isEmpty
                          ? 'https://github.com/login/device'
                          : state.verificationUri,
                    ),
                  ),
                ),
                CupertinoListTile.notched(
                  title: const Text('设备码'),
                  subtitle: Semantics(
                    identifier: 'device_flow_code_text',
                    liveRegion: true,
                    label: 'GitHub 设备码',
                    child: Text(
                      state.userCode.isEmpty ? '等待生成' : state.userCode,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: CupertinoColors.label,
                      ),
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
                identifier: 'start_device_flow_button',
                button: true,
                label: '开始 GitHub 授权',
                child: CupertinoButton.filled(
                  onPressed: state.canStartDeviceFlow
                      ? () {
                          context.read<TokenSettingsBloc>().add(
                            const TokenSettingsDeviceFlowRequested(),
                          );
                        }
                      : null,
                  child: state.isBusy
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.person_crop_circle_badge_checkmark,
                            ),
                            SizedBox(width: 6),
                            Text('使用 GitHub 授权'),
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
