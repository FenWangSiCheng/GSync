import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/home_counter_bloc.dart';
import '../bloc/home_counter_event.dart';
import '../bloc/home_counter_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCounterBloc(),
      child: const _HomeCounterView(),
    );
  }
}

class _HomeCounterView extends StatelessWidget {
  const _HomeCounterView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HomeCounterBloc, HomeCounterState>(
        builder: (context, state) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  identifier: 'home.counter.value',
                  child: Text(
                    'Steps: ${state.steps}',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      identifier: 'home.counter.increment',
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<HomeCounterBloc>().add(
                            const IncrementHomeCounter(),
                          );
                        },
                        child: const Text('+1'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Semantics(
                      identifier: 'home.counter.reset',
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<HomeCounterBloc>().add(
                            const ResetHomeCounter(),
                          );
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
