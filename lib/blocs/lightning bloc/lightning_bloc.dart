import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weather_dashboard/models/lightning_strike.dart';
import 'package:weather_dashboard/models/nearby_lightning_strike.dart';
import 'package:weather_dashboard/repositories/lightning_repository.dart';
import 'package:weather_dashboard/utils/distance_calculator.dart';

import 'lightning_event.dart';
import 'lightning_state.dart';

class LightningBloc extends Bloc<LightningEvent, LightningState> {
  LightningBloc({required LightningRepository repository})
    : _repository = repository,
      super(const LightningInitial()) {
    on<LightningStarted>(_onStarted);
    on<LightningLocationChanged>(_onLocationChanged);
    on<LightningPaused>(_onPaused);
    on<LightningResumed>(_onResumed);
    on<LightningRetried>(_onRetried);
    on<_LightningStrikeReceived>(_onStrikeReceived);
    on<_LightningStreamFailed>(_onStreamFailed);
  }

  static const double nearbyRadiusKm = 100;

  final LightningRepository _repository;

  StreamSubscription<LightningStrike>? _subscription;

  String? _cityName;
  double? _cityLatitude;
  double? _cityLongitude;

  LightningStrike? _latestReceivedStrike;
  NearbyLightningStrike? _latestNearbyStrike;

  int _nearbyStrikeCount = 0;
  bool _isPaused = false;
  int _subscriptionGeneration = 0;

  Future<void> _onStarted(
    LightningStarted event,
    Emitter<LightningState> emit,
  ) async {
    _latestReceivedStrike = null;
    _latestNearbyStrike = null;
    _nearbyStrikeCount = 0;
    _isPaused = false;

    await _startSubscription(emit: emit, preserveExistingData: false);
  }

  void _onLocationChanged(
    LightningLocationChanged event,
    Emitter<LightningState> emit,
  ) {
    _validateLocation(latitude: event.latitude, longitude: event.longitude);

    _cityName = event.cityName.trim();
    _cityLatitude = event.latitude;
    _cityLongitude = event.longitude;

    /*
     * Alerts from the previously selected city are no longer
     * relevant.
     */
    _latestNearbyStrike = null;
    _nearbyStrikeCount = 0;

    if (_isPaused) {
      emit(
        LightningPausedState(
          cityName: _cityName,
          latestNearbyStrike: null,
          nearbyStrikeCount: 0,
        ),
      );
      return;
    }

    final LightningState currentState = state;

    if (currentState is LightningFailure) {
      emit(
        LightningFailure(
          message: currentState.message,
          cityName: _cityName,
          latestNearbyStrike: null,
          nearbyStrikeCount: 0,
        ),
      );
      return;
    }

    /*
     * The echo server normally sends its first demo strike before
     * the weather request has finished. We cache that strike.
     *
     * As soon as the city's coordinates arrive, process the cached
     * strike immediately instead of waiting for the next timer.
     */
    final LightningStrike? cachedStrike = _latestReceivedStrike;

    if (LightningRepository.isDemoMode && cachedStrike != null) {
      _processStrike(receivedStrike: cachedStrike, emit: emit);
      return;
    }

    emit(
      LightningConnecting(
        cityName: _cityName,
        latestNearbyStrike: null,
        nearbyStrikeCount: 0,
      ),
    );
  }

  Future<void> _onRetried(
    LightningRetried event,
    Emitter<LightningState> emit,
  ) async {
    _isPaused = false;

    await _startSubscription(emit: emit, preserveExistingData: true);
  }

  Future<void> _startSubscription({
    required Emitter<LightningState> emit,
    required bool preserveExistingData,
  }) async {
    _subscriptionGeneration++;

    final int generation = _subscriptionGeneration;

    final StreamSubscription<LightningStrike>? oldSubscription = _subscription;

    _subscription = null;

    if (oldSubscription != null) {
      await oldSubscription.cancel();
    }

    if (!preserveExistingData) {
      _latestReceivedStrike = null;
      _latestNearbyStrike = null;
      _nearbyStrikeCount = 0;
    }

    emit(
      LightningConnecting(
        cityName: _cityName,
        latestNearbyStrike: _latestNearbyStrike,
        nearbyStrikeCount: _nearbyStrikeCount,
      ),
    );

    _subscription = _repository.watchLightning().listen(
      (LightningStrike strike) {
        add(_LightningStrikeReceived(strike: strike, generation: generation));
      },
      onError: (Object error, StackTrace stackTrace) {
        add(
          _LightningStreamFailed(
            error: error,
            stackTrace: stackTrace,
            generation: generation,
          ),
        );
      },
      cancelOnError: false,
    );
  }

  void _onStrikeReceived(
    _LightningStrikeReceived event,
    Emitter<LightningState> emit,
  ) {
    if (event.generation != _subscriptionGeneration || _isPaused) {
      return;
    }

    /*
     * Cache every valid strike, even if the weather request has not
     * supplied city coordinates yet.
     */
    _latestReceivedStrike = event.strike;

    _processStrike(receivedStrike: event.strike, emit: emit);
  }

  void _processStrike({
    required LightningStrike receivedStrike,
    required Emitter<LightningState> emit,
  }) {
    final double? cityLatitude = _cityLatitude;
    final double? cityLongitude = _cityLongitude;
    final String? cityName = _cityName;

    if (cityLatitude == null ||
        cityLongitude == null ||
        cityName == null ||
        cityName.isEmpty) {
      return;
    }

    final LightningStrike strike;

    if (LightningRepository.isDemoMode) {
      /*
       * The echo server only returns the data we send—it does not
       * know which weather city is selected.
       *
       * In demo mode, place the echoed strike approximately 5–6 km
       * from the selected city. The real distance calculator still
       * calculates the displayed distance.
       */
      strike = LightningStrike(
        id: receivedStrike.id,
        detectedAt: receivedStrike.detectedAt,
        latitude: (cityLatitude + 0.04).clamp(-90.0, 90.0).toDouble(),
        longitude: (cityLongitude + 0.04).clamp(-180.0, 180.0).toDouble(),
        quality: receivedStrike.quality,
        locationUncertaintyKm: receivedStrike.locationUncertaintyKm,
      );
    } else {
      /*
       * Production OpenWeather mode always uses the actual
       * coordinates received from its lightning stream.
       */
      strike = receivedStrike;
    }

    final double distanceKm = DistanceCalculator.calculateHaversineDistanceKm(
      firstLatitude: cityLatitude,
      firstLongitude: cityLongitude,
      secondLatitude: strike.latitude,
      secondLongitude: strike.longitude,
    );

    if (distanceKm > nearbyRadiusKm) {
      return;
    }

    final NearbyLightningStrike nearbyStrike = NearbyLightningStrike(
      strike: strike,
      cityName: cityName,
      distanceFromCityKm: distanceKm,
    );

    _latestNearbyStrike = nearbyStrike;
    _nearbyStrikeCount++;

    emit(
      LightningLive(
        latestNearbyStrike: nearbyStrike,
        nearbyStrikeCount: _nearbyStrikeCount,
      ),
    );
  }

  Future<void> _onPaused(
    LightningPaused event,
    Emitter<LightningState> emit,
  ) async {
    if (_isPaused) {
      return;
    }

    _isPaused = true;
    _subscription?.pause();

    emit(
      LightningPausedState(
        cityName: _cityName,
        latestNearbyStrike: _latestNearbyStrike,
        nearbyStrikeCount: _nearbyStrikeCount,
      ),
    );
  }

  Future<void> _onResumed(
    LightningResumed event,
    Emitter<LightningState> emit,
  ) async {
    if (!_isPaused) {
      return;
    }

    _isPaused = false;

    emit(
      LightningConnecting(
        cityName: _cityName,
        latestNearbyStrike: _latestNearbyStrike,
        nearbyStrikeCount: _nearbyStrikeCount,
      ),
    );

    _subscription?.resume();
  }

  void _onStreamFailed(
    _LightningStreamFailed event,
    Emitter<LightningState> emit,
  ) {
    if (event.generation != _subscriptionGeneration || _isPaused) {
      return;
    }

    emit(
      LightningFailure(
        message: _createFriendlyMessage(event.error),
        cityName: _cityName,
        latestNearbyStrike: _latestNearbyStrike,
        nearbyStrikeCount: _nearbyStrikeCount,
      ),
    );
  }

  void _validateLocation({
    required double latitude,
    required double longitude,
  }) {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'Latitude must be between -90 and 90.',
      );
    }

    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'Longitude must be between -180 and 180.',
      );
    }
  }

  String _createFriendlyMessage(Object error) {
    if (error is TimeoutException) {
      return 'The lightning service took too long to connect.';
    }

    if (error is SocketException) {
      return 'The lightning service could not reach the network.';
    }

    if (error is WebSocketException) {
      final String message = error.message;

      if (message.contains('APIKeyValidationError')) {
        return 'The API key does not have valid lightning access.';
      }

      if (message.contains('ExceededConnectionsLimitError')) {
        return 'The lightning connection limit has been reached.';
      }

      if (message.contains('OPENWEATHER_LIGHTNING_HOST')) {
        return 'The lightning WebSocket host was not configured.';
      }

      return message;
    }

    if (error is FormatException) {
      return 'The lightning service returned invalid data.';
    }

    return 'The live lightning stream encountered an error.';
  }

  @override
  Future<void> close() async {
    _subscriptionGeneration++;

    final StreamSubscription<LightningStrike>? currentSubscription =
        _subscription;

    _subscription = null;

    if (currentSubscription != null) {
      await currentSubscription.cancel();
    }

    return super.close();
  }
}

final class _LightningStrikeReceived extends LightningEvent {
  const _LightningStrikeReceived({
    required this.strike,
    required this.generation,
  });

  final LightningStrike strike;
  final int generation;
}

final class _LightningStreamFailed extends LightningEvent {
  const _LightningStreamFailed({
    required this.error,
    required this.stackTrace,
    required this.generation,
  });

  final Object error;
  final StackTrace stackTrace;
  final int generation;
}
