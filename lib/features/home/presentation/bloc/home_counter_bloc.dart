import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_counter_event.dart';
import 'home_counter_state.dart';

class HomeCounterBloc extends Bloc<HomeCounterEvent, HomeCounterState> {
  HomeCounterBloc() : super(const HomeCounterState.initial()) {
    on<IncrementHomeCounter>(_onIncrement);
    on<ResetHomeCounter>(_onReset);
  }

  void _onIncrement(
    IncrementHomeCounter event,
    Emitter<HomeCounterState> emit,
  ) {
    emit(HomeCounterState(steps: state.steps + 1));
  }

  void _onReset(ResetHomeCounter event, Emitter<HomeCounterState> emit) {
    emit(const HomeCounterState.initial());
  }
}
