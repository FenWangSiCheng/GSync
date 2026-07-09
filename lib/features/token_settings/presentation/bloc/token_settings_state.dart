part of 'token_settings_bloc.dart';

enum TokenSettingsStatus {
  idle,
  requestingDeviceCode,
  waitingForAuthorization,
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
    this.userCode = '',
    this.verificationUri = '',
  });

  final bool hasToken;
  final TokenSettingsStatus status;
  final String statusMessage;
  final String userCode;
  final String verificationUri;

  bool get isBusy {
    return status == TokenSettingsStatus.requestingDeviceCode ||
        status == TokenSettingsStatus.waitingForAuthorization ||
        status == TokenSettingsStatus.saving;
  }

  bool get canStartDeviceFlow => !isBusy;

  bool get canDelete => hasToken && !isBusy;

  TokenSettingsState copyWith({
    bool? hasToken,
    TokenSettingsStatus? status,
    String? statusMessage,
    String? userCode,
    String? verificationUri,
  }) {
    return TokenSettingsState(
      hasToken: hasToken ?? this.hasToken,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      userCode: userCode ?? this.userCode,
      verificationUri: verificationUri ?? this.verificationUri,
    );
  }

  @override
  List<Object?> get props => [
    hasToken,
    status,
    statusMessage,
    userCode,
    verificationUri,
  ];
}
