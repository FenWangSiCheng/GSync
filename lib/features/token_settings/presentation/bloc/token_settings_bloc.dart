import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/delete_git_token.dart';
import '../../domain/usecases/get_git_token.dart';
import '../../domain/usecases/poll_github_device_token.dart';
import '../../domain/usecases/request_github_device_authorization.dart';
import '../../domain/usecases/save_git_token.dart';
import '../../domain/entities/github_device_token_poll_result.dart';
import '../../domain/repositories/github_device_flow_repository.dart';

part 'token_settings_event.dart';
part 'token_settings_state.dart';

class TokenSettingsBloc extends Bloc<TokenSettingsEvent, TokenSettingsState> {
  TokenSettingsBloc({
    required GetGitToken getGitToken,
    required SaveGitToken saveGitToken,
    required DeleteGitToken deleteGitToken,
    required RequestGitHubDeviceAuthorization requestDeviceAuthorization,
    required PollGitHubDeviceToken pollDeviceToken,
  }) : _getGitToken = getGitToken,
       _saveGitToken = saveGitToken,
       _deleteGitToken = deleteGitToken,
       _requestDeviceAuthorization = requestDeviceAuthorization,
       _pollDeviceToken = pollDeviceToken,
       super(const TokenSettingsState()) {
    on<TokenSettingsStarted>(_onStarted);
    on<TokenSettingsDeviceFlowRequested>(_onDeviceFlowRequested);
    on<TokenSettingsDeleteRequested>(_onDeleteRequested);
  }

  final GetGitToken _getGitToken;
  final SaveGitToken _saveGitToken;
  final DeleteGitToken _deleteGitToken;
  final RequestGitHubDeviceAuthorization _requestDeviceAuthorization;
  final PollGitHubDeviceToken _pollDeviceToken;

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

  Future<void> _onDeviceFlowRequested(
    TokenSettingsDeviceFlowRequested event,
    Emitter<TokenSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TokenSettingsStatus.requestingDeviceCode,
        statusMessage: '正在向 GitHub 请求设备码。',
        userCode: '',
        verificationUri: '',
      ),
    );

    try {
      final authorization = await _requestDeviceAuthorization();
      emit(
        state.copyWith(
          status: TokenSettingsStatus.waitingForAuthorization,
          statusMessage: '请在浏览器打开 GitHub 设备授权页面并输入屏幕上的代码。',
          userCode: authorization.userCode,
          verificationUri: authorization.verificationUri.toString(),
        ),
      );

      var interval = authorization.interval;
      final expiresAt = DateTime.now().add(authorization.expiresIn);

      while (DateTime.now().isBefore(expiresAt)) {
        await Future<void>.delayed(interval);
        if (emit.isDone) return;

        final pollResult = await _pollDeviceToken(
          deviceCode: authorization.deviceCode,
        );

        switch (pollResult) {
          case GitHubDeviceTokenAuthorized(:final accessToken):
            emit(
              state.copyWith(
                status: TokenSettingsStatus.saving,
                statusMessage: 'GitHub 授权完成,正在安全保存访问令牌。',
              ),
            );
            await _saveGitToken(accessToken);
            if (emit.isDone) return;
            emit(
              state.copyWith(
                hasToken: true,
                status: TokenSettingsStatus.saved,
                statusMessage: 'GitHub 授权已安全保存。',
              ),
            );
            return;
          case GitHubDeviceTokenPending():
            _emitWaiting(emit, '正在等待 GitHub 授权完成。');
          case GitHubDeviceTokenSlowDown(interval: final slowedInterval):
            interval = slowedInterval;
            _emitWaiting(emit, 'GitHub 要求降低轮询频率,正在继续等待授权。');
          case GitHubDeviceTokenExpired():
            _emitFailure(emit, '设备码已过期,请重新开始 GitHub 授权。');
            return;
          case GitHubDeviceTokenDenied():
            _emitFailure(emit, 'GitHub 授权已取消。');
            return;
        }
      }

      _emitFailure(emit, '设备码已过期,请重新开始 GitHub 授权。');
    } on GitHubDeviceFlowException catch (error) {
      _emitFailure(emit, error.message);
    } on SaveGitTokenException catch (error) {
      _emitFailure(emit, error.message);
    } catch (_) {
      _emitFailure(emit, 'GitHub 授权失败。');
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
          userCode: '',
          verificationUri: '',
          statusMessage: 'GitHub 授权已删除。',
        ),
      );
    } catch (_) {
      _emitFailure(emit, 'GitHub 授权删除失败。');
    }
  }

  void _emitWaiting(Emitter<TokenSettingsState> emit, String message) {
    emit(
      state.copyWith(
        status: TokenSettingsStatus.waitingForAuthorization,
        statusMessage: message,
      ),
    );
  }

  void _emitFailure(Emitter<TokenSettingsState> emit, String message) {
    emit(
      state.copyWith(
        status: TokenSettingsStatus.failure,
        statusMessage: message,
      ),
    );
  }
}
