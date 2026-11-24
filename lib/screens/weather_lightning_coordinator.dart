import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/lightning bloc/lightning_bloc.dart';
import '../blocs/lightning bloc/lightning_event.dart';
import '../blocs/weather logic bloc/weather_bloc.dart';
import '../blocs/weather logic bloc/weather_state.dart';

class WeatherLightningCoordinator extends StatelessWidget {
  const WeatherLightningCoordinator({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<WeatherBloc, WeatherState>(
      listenWhen: (WeatherState previous, WeatherState current) {
        if (current is! WeatherLoaded) {
          return false;
        }

        if (previous is! WeatherLoaded) {
          return true;
        }

        final bool cityChanged =
            previous.weather.cityName != current.weather.cityName;

        final bool latitudeChanged =
            previous.weather.latitude != current.weather.latitude;

        final bool longitudeChanged =
            previous.weather.longitude != current.weather.longitude;

        return cityChanged || latitudeChanged || longitudeChanged;
      },
      listener: (BuildContext context, WeatherState state) {
        if (state is! WeatherLoaded) {
          return;
        }

        context.read<LightningBloc>().add(
          LightningLocationChanged(
            cityName: state.weather.cityName,
            latitude: state.weather.latitude,
            longitude: state.weather.longitude,
          ),
        );
      },
      child: child,
    );
  }
}
