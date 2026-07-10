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

class DirectorySyncRepositorySelected extends DirectorySyncEvent {
  const DirectorySyncRepositorySelected(this.fullName);

  final String fullName;

  @override
  List<Object?> get props => [fullName];
}

class DirectorySyncBranchSelected extends DirectorySyncEvent {
  const DirectorySyncBranchSelected(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

class DirectorySyncRequested extends DirectorySyncEvent {
  const DirectorySyncRequested();
}
