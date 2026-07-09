part of 'token_settings_bloc.dart';

enum TokenSettingsStatus {
  idle,
  openingBrowser,
  waitingForCallback,
  saving,
  saved,
  deleted,
  failure,
}

class TokenSettingsState extends Equatable {
  const TokenSettingsState({
    this.hasToken = false,
    this.status = TokenSettingsStatus.idle,
    this.statusMessage = '正在检查访问令牌。',
    this.oauthRedirectUrl = '',
    this.oauthCallbackStatus = '',
  });

  final bool hasToken;
  final TokenSettingsStatus status;
  final String statusMessage;
  final String oauthRedirectUrl;
  final String oauthCallbackStatus;

  bool get isBusy {
    return status == TokenSettingsStatus.openingBrowser ||
        status == TokenSettingsStatus.waitingForCallback ||
        status == TokenSettingsStatus.saving;
  }

  bool get canStartOAuthRedirect => !isBusy;

  bool get canDelete => hasToken && !isBusy;

  TokenSettingsState copyWith({
    bool? hasToken,
    TokenSettingsStatus? status,
    String? statusMessage,
    String? oauthRedirectUrl,
    String? oauthCallbackStatus,
  }) {
    return TokenSettingsState(
      hasToken: hasToken ?? this.hasToken,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      oauthRedirectUrl: oauthRedirectUrl ?? this.oauthRedirectUrl,
      oauthCallbackStatus: oauthCallbackStatus ?? this.oauthCallbackStatus,
    );
  }

  @override
  List<Object?> get props => [
    hasToken,
    status,
    statusMessage,
    oauthRedirectUrl,
    oauthCallbackStatus,
  ];
}
