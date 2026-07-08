part of 'token_settings_bloc.dart';

sealed class TokenSettingsEvent extends Equatable {
  const TokenSettingsEvent();

  @override
  List<Object?> get props => [];
}

class TokenSettingsStarted extends TokenSettingsEvent {
  const TokenSettingsStarted();
}

class TokenSettingsTokenChanged extends TokenSettingsEvent {
  const TokenSettingsTokenChanged(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class TokenSettingsSaveRequested extends TokenSettingsEvent {
  const TokenSettingsSaveRequested();
}

class TokenSettingsDeleteRequested extends TokenSettingsEvent {
  const TokenSettingsDeleteRequested();
}
