import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weather_dashboard/blocs/lightning bloc/lightning_bloc.dart';
import 'package:weather_dashboard/blocs/lightning bloc/lightning_event.dart';

class AppLifecycleManager extends StatefulWidget {
  const AppLifecycleManager({required this.child, super.key});

  final Widget child;

  @override
  State<AppLifecycleManager> createState() {
    return _AppLifecycleManagerState();
  }
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        context.read<LightningBloc>().add(const LightningResumed());

      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        context.read<LightningBloc>().add(const LightningPaused());

      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
