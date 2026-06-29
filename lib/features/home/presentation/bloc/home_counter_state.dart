import 'package:equatable/equatable.dart';

class HomeCounterState extends Equatable {
  final int steps;

  const HomeCounterState({required this.steps});

  const HomeCounterState.initial() : steps = 0;

  @override
  List<Object> get props => [steps];
}
