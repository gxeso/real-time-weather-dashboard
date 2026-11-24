import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/weather_data.dart';
import '../../repositories/weather_repository.dart';
import 'weather_event.dart';
import 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc({required WeatherRepository repository})
    : _repository = repository,
      super(const WeatherInitial()) {
    on<WeatherStarted>(_onStarted);
    on<WeatherCityChanged>(_onCityChanged);
    on<WeatherRetried>(_onRetried);
    on<WeatherPaused>(_onPaused);
    on<WeatherResumed>(_onResumed);
    on<WeatherDataReceived>(_onDataReceived);
    on<WeatherStreamFailed>(_onStreamFailed);
  }

  final WeatherRepository _repository;

  StreamSubscription<WeatherData>? _weatherSubscription;

  String _currentCity = 'Dubai';

  Future<void> _onStarted(
    WeatherStarted event,
    Emitter<WeatherState> emit,
  ) async {
    await _startWeatherStream(event.city, emit);
  }

  Future<void> _onCityChanged(
    WeatherCityChanged event,
    Emitter<WeatherState> emit,
  ) async {
    await _startWeatherStream(event.city, emit);
  }

  Future<void> _onRetried(
    WeatherRetried event,
    Emitter<WeatherState> emit,
  ) async {
    await _startWeatherStream(_currentCity, emit);
  }

  void _onPaused(WeatherPaused event, Emitter<WeatherState> emit) {
    _weatherSubscription?.pause();
  }

  Future<void> _onResumed(
    WeatherResumed event,
    Emitter<WeatherState> emit,
  ) async {
    final StreamSubscription<WeatherData>? subscription = _weatherSubscription;

    if (subscription == null) {
      await _startWeatherStream(_currentCity, emit);
      return;
    }

    if (subscription.isPaused) {
      subscription.resume();
    }
  }

  void _onDataReceived(WeatherDataReceived event, Emitter<WeatherState> emit) {
    emit(WeatherLoaded(event.weather));
  }

  void _onStreamFailed(WeatherStreamFailed event, Emitter<WeatherState> emit) {
    emit(
      WeatherError(city: _currentCity, message: _messageForError(event.error)),
    );
  }

  Future<void> _startWeatherStream(
    String city,
    Emitter<WeatherState> emit,
  ) async {
    final String normalizedCity = city.trim();

    if (normalizedCity.isEmpty) {
      emit(const WeatherError(city: '', message: 'Please enter a city name.'));
      return;
    }

    _currentCity = normalizedCity;

    emit(WeatherLoading(_currentCity));

    await _weatherSubscription?.cancel();

    _weatherSubscription = _repository
        .watchWeather(_currentCity)
        .listen(
          (WeatherData weather) {
            add(WeatherDataReceived(weather));
          },
          onError: (Object error, StackTrace stackTrace) {
            add(WeatherStreamFailed(error));
          },
        );
  }

  String _messageForError(Object error) {
    if (error is SocketException) {
      return 'No internet connection. Check your network and try again.';
    }

    if (error is TimeoutException) {
      return 'The weather request timed out. Please try again.';
    }

    if (error is FormatException) {
      return 'The weather service returned invalid data.';
    }

    if (error is HttpException) {
      final String message = error.message.toLowerCase();

      if (message.contains('401')) {
        return 'The OpenWeather API key is invalid or inactive.';
      }

      if (message.contains('404') || message.contains('city not found')) {
        return 'City not found. Check the spelling and try again.';
      }

      if (message.contains('429')) {
        return 'Too many weather requests. Please wait and try again.';
      }

      return 'The weather service could not complete the request.';
    }

    return 'Something unexpected happened. Please try again.';
  }

  @override
  Future<void> close() async {
    await _weatherSubscription?.cancel();
    return super.close();
  }
}
