import 'package:equatable/equatable.dart';

enum DirectorySyncResultType { success, noChanges, failure }

class DirectorySyncResult extends Equatable {
  const DirectorySyncResult._({
    required this.type,
    required this.message,
    this.commitHash,
  });

  factory DirectorySyncResult.success({
    required String message,
    String? commitHash,
  }) {
    return DirectorySyncResult._(
      type: DirectorySyncResultType.success,
      message: message,
      commitHash: commitHash,
    );
  }

  factory DirectorySyncResult.noChanges({required String message}) {
    return DirectorySyncResult._(
      type: DirectorySyncResultType.noChanges,
      message: message,
    );
  }

  factory DirectorySyncResult.failure({required String message}) {
    return DirectorySyncResult._(
      type: DirectorySyncResultType.failure,
      message: message,
    );
  }

  final DirectorySyncResultType type;
  final String message;
  final String? commitHash;

  bool get isSuccess => type != DirectorySyncResultType.failure;

  @override
  List<Object?> get props => [type, message, commitHash];
}
