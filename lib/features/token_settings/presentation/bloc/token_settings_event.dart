part of 'token_settings_bloc.dart';

sealed class TokenSettingsEvent extends Equatable {
  const TokenSettingsEvent();

  @override
  List<Object?> get props => [];
}

class TokenSettingsStarted extends TokenSettingsEvent {
  const TokenSettingsStarted();
}

class TokenSettingsDeviceFlowRequested extends TokenSettingsEvent {
  const TokenSettingsDeviceFlowRequested();
}

class TokenSettingsDeleteRequested extends TokenSettingsEvent {
  const TokenSettingsDeleteRequested();
}
