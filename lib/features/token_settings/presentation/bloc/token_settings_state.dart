part of 'token_settings_bloc.dart';

enum TokenSettingsStatus { idle, saving, saved, deleted, failure }

class TokenSettingsState extends Equatable {
  const TokenSettingsState({
    this.inputToken = '',
    this.hasToken = false,
    this.status = TokenSettingsStatus.idle,
    this.statusMessage = '正在检查访问令牌。',
  });

  final String inputToken;
  final bool hasToken;
  final TokenSettingsStatus status;
  final String statusMessage;

  bool get canSave {
    return inputToken.trim().isNotEmpty && status != TokenSettingsStatus.saving;
  }

  bool get canDelete {
    return hasToken && status != TokenSettingsStatus.saving;
  }

  TokenSettingsState copyWith({
    String? inputToken,
    bool? hasToken,
    TokenSettingsStatus? status,
    String? statusMessage,
  }) {
    return TokenSettingsState(
      inputToken: inputToken ?? this.inputToken,
      hasToken: hasToken ?? this.hasToken,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  @override
  List<Object?> get props => [inputToken, hasToken, status, statusMessage];
}
