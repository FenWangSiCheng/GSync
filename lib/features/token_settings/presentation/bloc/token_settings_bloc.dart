import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/delete_git_token.dart';
import '../../domain/usecases/get_git_token.dart';
import '../../domain/usecases/save_git_token.dart';

part 'token_settings_event.dart';
part 'token_settings_state.dart';

class TokenSettingsBloc extends Bloc<TokenSettingsEvent, TokenSettingsState> {
  TokenSettingsBloc({
    required GetGitToken getGitToken,
    required SaveGitToken saveGitToken,
    required DeleteGitToken deleteGitToken,
  }) : _getGitToken = getGitToken,
       _saveGitToken = saveGitToken,
       _deleteGitToken = deleteGitToken,
       super(const TokenSettingsState()) {
    on<TokenSettingsStarted>(_onStarted);
    on<TokenSettingsTokenChanged>(_onTokenChanged);
    on<TokenSettingsSaveRequested>(_onSaveRequested);
    on<TokenSettingsDeleteRequested>(_onDeleteRequested);
  }

  final GetGitToken _getGitToken;
  final SaveGitToken _saveGitToken;
  final DeleteGitToken _deleteGitToken;

  Future<void> _onStarted(
    TokenSettingsStarted event,
    Emitter<TokenSettingsState> emit,
  ) async {
    final token = await _getGitToken();
    emit(
      state.copyWith(
        hasToken: token != null,
        status: TokenSettingsStatus.idle,
        statusMessage: token == null ? '未保存访问令牌。' : '访问令牌已安全保存。',
      ),
    );
  }

  void _onTokenChanged(
    TokenSettingsTokenChanged event,
    Emitter<TokenSettingsState> emit,
  ) {
    emit(state.copyWith(inputToken: event.value));
  }

  Future<void> _onSaveRequested(
    TokenSettingsSaveRequested event,
    Emitter<TokenSettingsState> emit,
  ) async {
    emit(state.copyWith(status: TokenSettingsStatus.saving));
    try {
      await _saveGitToken(state.inputToken);
      emit(
        state.copyWith(
          inputToken: '',
          hasToken: true,
          status: TokenSettingsStatus.saved,
          statusMessage: '访问令牌已安全保存。',
        ),
      );
    } on SaveGitTokenException catch (error) {
      emit(
        state.copyWith(
          status: TokenSettingsStatus.failure,
          statusMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: TokenSettingsStatus.failure,
          statusMessage: '访问令牌保存失败。',
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
          inputToken: '',
          hasToken: false,
          status: TokenSettingsStatus.deleted,
          statusMessage: '访问令牌已删除。',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: TokenSettingsStatus.failure,
          statusMessage: '访问令牌删除失败。',
        ),
      );
    }
  }
}
