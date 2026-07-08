part of 'directory_sync_bloc.dart';

sealed class DirectorySyncEvent extends Equatable {
  const DirectorySyncEvent();

  @override
  List<Object?> get props => [];
}

class DirectorySyncStarted extends DirectorySyncEvent {
  const DirectorySyncStarted();
}

class DirectorySyncSystemDirectoryRequested extends DirectorySyncEvent {
  const DirectorySyncSystemDirectoryRequested();
}

class DirectorySyncTokenStatusRequested extends DirectorySyncEvent {
  const DirectorySyncTokenStatusRequested();
}

class DirectorySyncRemoteUrlChanged extends DirectorySyncEvent {
  const DirectorySyncRemoteUrlChanged(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class DirectorySyncRequested extends DirectorySyncEvent {
  const DirectorySyncRequested();
}
