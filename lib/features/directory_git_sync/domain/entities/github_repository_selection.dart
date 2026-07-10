import 'package:equatable/equatable.dart';

class GitHubRepositorySummary extends Equatable {
  const GitHubRepositorySummary({
    required this.owner,
    required this.name,
    required this.fullName,
    required this.defaultBranch,
    required this.htmlUrl,
    required this.isPrivate,
  });

  final String owner;
  final String name;
  final String fullName;
  final String defaultBranch;
  final String htmlUrl;
  final bool isPrivate;

  @override
  List<Object?> get props => [
    owner,
    name,
    fullName,
    defaultBranch,
    htmlUrl,
    isPrivate,
  ];
}

class GitHubBranchSummary extends Equatable {
  const GitHubBranchSummary({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}
