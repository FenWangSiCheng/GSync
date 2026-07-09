import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/router_constants.dart';
import '../bloc/token_settings_bloc.dart';

class TokenSettingsPage extends StatefulWidget {
  const TokenSettingsPage({super.key, this.initialOAuthCallback});

  final Uri? initialOAuthCallback;

  @override
  State<TokenSettingsPage> createState() => _TokenSettingsPageState();
}

class _TokenSettingsPageState extends State<TokenSettingsPage> {
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _listenForOAuthCallbacks();
    final initialOAuthCallback = widget.initialOAuthCallback;
    if (initialOAuthCallback != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLink(initialOAuthCallback);
      });
    }
  }

  void _listenForOAuthCallbacks() {
    final appLinks = AppLinks();
    _linkSubscription = appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    if (!mounted || uri.host != 'oauth' || uri.path != '/github/callback') {
      return;
    }
    context.read<TokenSettingsBloc>().add(
      TokenSettingsOAuthCallbackReceived(uri),
    );
  }

  void _returnToSync() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RouterPaths.home);
  }

  @override
  void dispose() {
    unawaited(_linkSubscription?.cancel());
    super.dispose();
  }

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
              onPressed: _returnToSync,
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
              header: const Text('浏览器授权'),
              footer: const Text('打开 GitHub 完成授权后,会自动回到 GitSync 并保存访问令牌。'),
              hasLeading: false,
              children: [
                CupertinoListTile.notched(
                  title: const Text('授权地址'),
                  subtitle: Semantics(
                    identifier: 'oauth_redirect_url_text',
                    liveRegion: true,
                    label: 'GitHub OAuth 授权地址',
                    child: Text(
                      state.oauthRedirectUrl.isEmpty
                          ? '等待打开 GitHub 授权页面'
                          : state.oauthRedirectUrl,
                    ),
                  ),
                ),
                CupertinoListTile.notched(
                  title: const Text('回调状态'),
                  subtitle: Semantics(
                    identifier: 'oauth_callback_status_text',
                    liveRegion: true,
                    label: 'GitHub OAuth 回调状态',
                    child: Text(
                      state.oauthCallbackStatus.isEmpty
                          ? '等待开始授权'
                          : state.oauthCallbackStatus,
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
                identifier: 'start_oauth_redirect_button',
                button: true,
                label: '打开 GitHub 授权',
                child: CupertinoButton.filled(
                  onPressed: state.canStartOAuthRedirect
                      ? () {
                          context.read<TokenSettingsBloc>().add(
                            const TokenSettingsOAuthRedirectRequested(),
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
