part of 'token_settings_bloc.dart';

sealed class TokenSettingsEvent extends Equatable {
  const TokenSettingsEvent();

  @override
  List<Object?> get props => [];
}

class TokenSettingsStarted extends TokenSettingsEvent {
  const TokenSettingsStarted();
}

class TokenSettingsOAuthRedirectRequested extends TokenSettingsEvent {
  const TokenSettingsOAuthRedirectRequested();
}

class TokenSettingsOAuthCallbackReceived extends TokenSettingsEvent {
  const TokenSettingsOAuthCallbackReceived(this.callbackUri);

  final Uri callbackUri;

  @override
  List<Object?> get props => [callbackUri];
}

class TokenSettingsDeleteRequested extends TokenSettingsEvent {
  const TokenSettingsDeleteRequested();
}
