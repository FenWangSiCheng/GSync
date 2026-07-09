import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/delete_git_token.dart';
import '../../domain/usecases/get_git_token.dart';
import '../../domain/usecases/save_git_token.dart';
import '../../domain/usecases/start_github_oauth_redirect_authorization.dart';
import '../../domain/usecases/complete_github_oauth_redirect_authorization.dart';
import '../../domain/repositories/github_oauth_redirect_repository.dart';

part 'token_settings_event.dart';
part 'token_settings_state.dart';

class TokenSettingsBloc extends Bloc<TokenSettingsEvent, TokenSettingsState> {
  TokenSettingsBloc({
    required GetGitToken getGitToken,
    required SaveGitToken saveGitToken,
    required DeleteGitToken deleteGitToken,
    required StartGitHubOAuthRedirectAuthorization
    startOAuthRedirectAuthorization,
    required CompleteGitHubOAuthRedirectAuthorization
    completeOAuthRedirectAuthorization,
  }) : _getGitToken = getGitToken,
       _saveGitToken = saveGitToken,
       _deleteGitToken = deleteGitToken,
       _startOAuthRedirectAuthorization = startOAuthRedirectAuthorization,
       _completeOAuthRedirectAuthorization = completeOAuthRedirectAuthorization,
       super(const TokenSettingsState()) {
    on<TokenSettingsStarted>(_onStarted);
    on<TokenSettingsOAuthRedirectRequested>(_onOAuthRedirectRequested);
    on<TokenSettingsOAuthCallbackReceived>(_onOAuthCallbackReceived);
    on<TokenSettingsDeleteRequested>(_onDeleteRequested);
  }

  final GetGitToken _getGitToken;
  final SaveGitToken _saveGitToken;
  final DeleteGitToken _deleteGitToken;
  final StartGitHubOAuthRedirectAuthorization _startOAuthRedirectAuthorization;
  final CompleteGitHubOAuthRedirectAuthorization
  _completeOAuthRedirectAuthorization;

  Future<void> _onStarted(
    TokenSettingsStarted event,
    Emitter<TokenSettingsState> emit,
  ) async {
    final token = await _getGitToken();
    emit(
      state.copyWith(
        hasToken: token != null,
        status: TokenSettingsStatus.idle,
        statusMessage: token == null ? '未完成 GitHub 授权。' : 'GitHub 授权已安全保存。',
      ),
    );
  }

  Future<void> _onOAuthRedirectRequested(
    TokenSettingsOAuthRedirectRequested event,
    Emitter<TokenSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TokenSettingsStatus.openingBrowser,
        statusMessage: '正在打开 GitHub 授权页面。',
        oauthRedirectUrl: '',
        oauthCallbackStatus: '',
      ),
    );

    try {
      final session = await _startOAuthRedirectAuthorization();
      emit(
        state.copyWith(
          status: TokenSettingsStatus.waitingForCallback,
          statusMessage: '请在 GitHub 完成授权,授权后会自动回到 GitSync。',
          oauthRedirectUrl: session.authorizationUrl.toString(),
          oauthCallbackStatus: '正在等待 GitHub 授权回调。',
        ),
      );
    } on GitHubOAuthRedirectException catch (error) {
      emit(
        state.copyWith(
          status: TokenSettingsStatus.failure,
          statusMessage: error.message,
          oauthCallbackStatus: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: TokenSettingsStatus.failure,
          statusMessage: 'GitHub 授权页面打开失败。',
          oauthCallbackStatus: 'GitHub 授权页面打开失败。',
        ),
      );
    }
  }

  Future<void> _onOAuthCallbackReceived(
    TokenSettingsOAuthCallbackReceived event,
    Emitter<TokenSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TokenSettingsStatus.saving,
        statusMessage: 'GitHub 授权完成,正在安全保存访问令牌。',
        oauthCallbackStatus: '已收到 GitHub 授权回调。',
      ),
    );

    try {
      final token = await _completeOAuthRedirectAuthorization(
        callbackUri: event.callbackUri,
      );
      await _saveGitToken(token.accessToken);
      if (emit.isDone) return;
      emit(
        state.copyWith(
          hasToken: true,
          status: TokenSettingsStatus.saved,
          statusMessage: 'GitHub 授权已安全保存。',
          oauthCallbackStatus: 'GitHub 授权回调处理完成。',
        ),
      );
    } on GitHubOAuthRedirectException catch (error) {
      emit(
        state.copyWith(
          status: TokenSettingsStatus.failure,
          statusMessage: error.message,
          oauthCallbackStatus: error.message,
        ),
      );
    } on SaveGitTokenException catch (error) {
      emit(
        state.copyWith(
          status: TokenSettingsStatus.failure,
          statusMessage: error.message,
          oauthCallbackStatus: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: TokenSettingsStatus.failure,
          statusMessage: 'GitHub 授权失败。',
          oauthCallbackStatus: 'GitHub 授权失败。',
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    TokenSettingsDeleteRequested event,
    Emitter<TokenSettingsState> emit,
  ) async {
    emit(state.copyWith(status: TokenSettingsStatus.saving));
    try {
      await _deleteGitToken();
      emit(
        state.copyWith(
          hasToken: false,
          status: TokenSettingsStatus.deleted,
          oauthRedirectUrl: '',
          oauthCallbackStatus: '',
          statusMessage: 'GitHub 授权已删除。',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: TokenSettingsStatus.failure,
          statusMessage: 'GitHub 授权删除失败。',
        ),
      );
    }
  }
}
