import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../models/weather_data.dart';

class WeatherRepository {
  static const String _apiKey = String.fromEnvironment('OPENWEATHER_API_KEY');

  static const Duration _timeout = Duration(seconds: 5);

  static const Duration _pollingInterval = Duration(seconds: 10);

  Future<WeatherData> fetchWeather(String city) async {
    final String normalizedCity = city.trim();

    if (normalizedCity.isEmpty) {
      throw const FormatException('The city name cannot be empty.');
    }

    if (_apiKey.isEmpty) {
      throw const HttpException('The OpenWeather API key was not provided.');
    }

    final Uri endpoint = Uri.https(
      'api.openweathermap.org',
      '/data/2.5/weather',
      {'q': normalizedCity, 'appid': _apiKey, 'units': 'metric'},
    );

    final HttpClient client = HttpClient();
    final Stopwatch stopwatch = Stopwatch()..start();

    developer.log(
      'Fetching weather for $normalizedCity',
      name: 'WeatherRepository',
    );

    try {
      final HttpClientRequest request = await client
          .getUrl(endpoint)
          .timeout(_timeout);

      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final HttpClientResponse response = await request.close().timeout(
        _timeout,
      );

      final String responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_timeout);

      if (response.statusCode != HttpStatus.ok) {
        final String apiMessage = _extractErrorMessage(responseBody);

        throw HttpException(
          'Weather request failed '
          '(${response.statusCode}): $apiMessage',
          uri: endpoint,
        );
      }

      final dynamic decodedJson = jsonDecode(responseBody);

      if (decodedJson is! Map<String, dynamic>) {
        throw const FormatException('The API returned an unexpected format.');
      }

      final WeatherData weather = WeatherData.fromJson(decodedJson);

      developer.log(
        'Weather fetched successfully in '
        '${stopwatch.elapsedMilliseconds} ms',
        name: 'WeatherRepository',
      );

      return weather;
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'The weather request timed out.',
        name: 'WeatherRepository',
        error: error,
        stackTrace: stackTrace,
      );

      throw TimeoutException('The weather request took too long.', _timeout);
    } on Object catch (error, stackTrace) {
      developer.log(
        'The weather request failed.',
        name: 'WeatherRepository',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    } finally {
      stopwatch.stop();
      client.close(force: true);
    }
  }

  Stream<WeatherData> watchWeather(String city) {
    late final StreamController<WeatherData> controller;

    Timer? pollingTimer;
    bool isFetching = false;

    Future<void> emitWeather() async {
      if (isFetching || controller.isClosed) {
        return;
      }

      isFetching = true;

      try {
        final WeatherData weather = await fetchWeather(city);

        if (!controller.isClosed) {
          controller.add(weather);
        }
      } on Object catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      } finally {
        isFetching = false;
      }
    }

    void startPolling() {
      pollingTimer?.cancel();

      unawaited(emitWeather());

      pollingTimer = Timer.periodic(
        _pollingInterval,
        (_) => unawaited(emitWeather()),
      );

      developer.log(
        'Weather polling started for $city',
        name: 'WeatherRepository',
      );
    }

    void stopPolling() {
      pollingTimer?.cancel();
      pollingTimer = null;

      developer.log(
        'Weather polling stopped for $city',
        name: 'WeatherRepository',
      );
    }

    controller = StreamController<WeatherData>(
      onListen: startPolling,
      onPause: stopPolling,
      onResume: startPolling,
      onCancel: stopPolling,
    );

    return controller.stream;
  }

  String _extractErrorMessage(String responseBody) {
    try {
      final dynamic decodedJson = jsonDecode(responseBody);

      if (decodedJson is Map<String, dynamic>) {
        return decodedJson['message']?.toString() ?? 'Unknown API error.';
      }
    } on FormatException {
      // The error response was not valid JSON.
    }

    return 'Unknown API error.';
  }
}
