import '../../models/weather_data.dart';

sealed class WeatherEvent {
  const WeatherEvent();
}

final class WeatherStarted extends WeatherEvent {
  const WeatherStarted(this.city);

  final String city;
}

final class WeatherCityChanged extends WeatherEvent {
  const WeatherCityChanged(this.city);

  final String city;
}

final class WeatherRetried extends WeatherEvent {
  const WeatherRetried();
}

final class WeatherPaused extends WeatherEvent {
  const WeatherPaused();
}

final class WeatherResumed extends WeatherEvent {
  const WeatherResumed();
}

final class WeatherDataReceived extends WeatherEvent {
  const WeatherDataReceived(this.weather);

  final WeatherData weather;
}

final class WeatherStreamFailed extends WeatherEvent {
  const WeatherStreamFailed(this.error);

  final Object error;
}
