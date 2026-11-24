import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_theme.dart';
import 'blocs/city search bloc/city_search_bloc.dart';
import 'blocs/lightning bloc/lightning_bloc.dart';
import 'blocs/lightning bloc/lightning_event.dart';
import 'blocs/theme bloc/theme_bloc.dart';
import 'blocs/theme bloc/theme_state.dart';
import 'blocs/weather logic bloc/weather_bloc.dart';
import 'repositories/city_repository.dart';
import 'repositories/lightning_repository.dart';
import 'repositories/weather_repository.dart';
import 'screens/app_lifecycle_manager.dart';
import 'screens/app_splash_screen.dart';
import 'screens/weather_lightning_coordinator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<WeatherRepository>(
          create: (_) => WeatherRepository(),
        ),
        RepositoryProvider<CityRepository>(create: (_) => CityRepository()),
        RepositoryProvider<LightningRepository>(
          create: (_) => LightningRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
          BlocProvider<WeatherBloc>(
            create: (context) =>
                WeatherBloc(repository: context.read<WeatherRepository>()),
          ),
          BlocProvider<CitySearchBloc>(
            create: (context) =>
                CitySearchBloc(repository: context.read<CityRepository>()),
          ),
          BlocProvider<LightningBloc>(
            create: (context) =>
                LightningBloc(repository: context.read<LightningRepository>())
                  ..add(const LightningStarted()),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              title: 'Atmos Weather',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeState.themeMode,
              themeAnimationDuration: const Duration(milliseconds: 350),
              themeAnimationCurve: Curves.easeInOut,
              builder: (context, child) {
                return AppLifecycleManager(
                  child: WeatherLightningCoordinator(
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
              home: const AppSplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
