import '../../models/weather_data.dart';

sealed class WeatherState {
  const WeatherState();
}

final class WeatherInitial extends WeatherState {
  const WeatherInitial();
}

final class WeatherLoading extends WeatherState {
  const WeatherLoading(this.city);

  final String city;
}

final class WeatherLoaded extends WeatherState {
  const WeatherLoaded(this.weather);

  final WeatherData weather;
}

final class WeatherError extends WeatherState {
  const WeatherError({required this.city, required this.message});

  final String city;
  final String message;
}
