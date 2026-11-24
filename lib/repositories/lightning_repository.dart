import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../models/lightning_strike.dart';

class LightningRepository {
  static const String _apiKey = String.fromEnvironment('OPENWEATHER_API_KEY');

  static const String _streamHost = String.fromEnvironment(
    'OPENWEATHER_LIGHTNING_HOST',
  );

  /// Demo mode is enabled by default for now.
  ///
  /// Demo:
  /// wss://echo.websocket.org
  ///
  /// Production:
  /// OpenWeather's assigned WebSocket host.
  static const bool isDemoMode = bool.fromEnvironment(
    'LIGHTNING_DEMO_MODE',
    defaultValue: true,
  );

  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const Duration _pingInterval = Duration(seconds: 20);
  static const Duration _demoStrikeInterval = Duration(seconds: 5);

  Stream<LightningStrike> watchLightning() {
    late final StreamController<LightningStrike> controller;

    WebSocket? socket;
    StreamSubscription<dynamic>? socketSubscription;
    Timer? demoTimer;

    bool isConnecting = false;
    bool isClosingIntentionally = false;

    Future<void> closeSocket() async {
      isClosingIntentionally = true;

      demoTimer?.cancel();
      demoTimer = null;

      final StreamSubscription<dynamic>? currentSubscription =
          socketSubscription;

      socketSubscription = null;

      if (currentSubscription != null) {
        await currentSubscription.cancel();
      }

      final WebSocket? currentSocket = socket;
      socket = null;

      if (currentSocket != null) {
        await currentSocket.close(
          WebSocketStatus.normalClosure,
          'Lightning stream stopped.',
        );
      }

      isConnecting = false;

      developer.log('Lightning WebSocket closed.', name: 'LightningRepository');
    }

    void sendDemoStrike() {
      final WebSocket? currentSocket = socket;

      if (currentSocket == null || currentSocket.readyState != WebSocket.open) {
        return;
      }

      final DateTime now = DateTime.now().toUtc();

      final Map<String, dynamic> simulatedStrike = {
        'id': 'demo-${now.microsecondsSinceEpoch}',
        'date': now.toIso8601String(),
        'lat': 25.2048,
        'lon': 55.2708,
        'quality': 'good',
        'error': 1.2,
      };

      currentSocket.add(jsonEncode(simulatedStrike));

      developer.log(
        'Demo lightning strike sent to the echo server.',
        name: 'LightningRepository',
      );
    }

    Future<void> connect() async {
      if (isConnecting || socket != null || controller.isClosed) {
        return;
      }

      if (!isDemoMode && _apiKey.isEmpty) {
        controller.addError(
          const WebSocketException('The OpenWeather API key was not provided.'),
        );
        return;
      }

      if (!isDemoMode && _streamHost.isEmpty) {
        controller.addError(
          const WebSocketException(
            'The OpenWeather lightning stream host was not provided.',
          ),
        );
        return;
      }

      if (!isDemoMode &&
          (_streamHost.contains('://') || _streamHost.contains('/'))) {
        controller.addError(
          const FormatException(
            'OPENWEATHER_LIGHTNING_HOST must contain only '
            'the hostname, without wss:// or a path.',
          ),
        );
        return;
      }

      isConnecting = true;
      isClosingIntentionally = false;

      final Uri endpoint = isDemoMode
          ? Uri.parse('wss://echo.websocket.org')
          : Uri(
              scheme: 'wss',
              host: _streamHost,
              path: '/',
              queryParameters: {'apikey': _apiKey},
            );

      developer.log(
        isDemoMode
            ? 'Connecting to the WebSocket echo server in demo mode.'
            : 'Connecting to the OpenWeather lightning stream.',
        name: 'LightningRepository',
      );

      try {
        final WebSocket connectedSocket = await WebSocket.connect(
          endpoint.toString(),
        ).timeout(_connectionTimeout);

        if (controller.isClosed || isClosingIntentionally) {
          await connectedSocket.close(
            WebSocketStatus.normalClosure,
            'Listener is no longer active.',
          );
          return;
        }

        socket = connectedSocket;
        connectedSocket.pingInterval = _pingInterval;

        developer.log(
          isDemoMode
              ? 'Demo WebSocket connected.'
              : 'Lightning WebSocket connected.',
          name: 'LightningRepository',
        );

        socketSubscription = connectedSocket.listen(
          (dynamic message) {
            try {
              final LightningStrike? strike = isDemoMode
                  ? _tryParseDemoMessage(message)
                  : _parseMessage(message);

              /*
               * The echo server can send a plain-text welcome message.
               * It is not lightning JSON, so demo mode safely ignores it.
               */
              if (strike == null) {
                developer.log(
                  'Ignored a non-lightning echo-server message.',
                  name: 'LightningRepository',
                );
                return;
              }

              if (!controller.isClosed) {
                controller.add(strike);
              }

              developer.log(
                isDemoMode
                    ? 'Simulated lightning strike echoed successfully.'
                    : 'Live lightning strike received.',
                name: 'LightningRepository',
              );
            } on Object catch (error, stackTrace) {
              developer.log(
                'Failed to parse a lightning message.',
                name: 'LightningRepository',
                error: error,
                stackTrace: stackTrace,
              );

              if (!controller.isClosed) {
                controller.addError(error, stackTrace);
              }
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            developer.log(
              'Lightning WebSocket failed.',
              name: 'LightningRepository',
              error: error,
              stackTrace: stackTrace,
            );

            demoTimer?.cancel();
            demoTimer = null;
            socket = null;
            socketSubscription = null;

            if (!controller.isClosed && !isClosingIntentionally) {
              controller.addError(error, stackTrace);
            }
          },
          onDone: () {
            final int? closeCode = connectedSocket.closeCode;
            final String? closeReason = connectedSocket.closeReason;

            demoTimer?.cancel();
            demoTimer = null;
            socket = null;
            socketSubscription = null;

            developer.log(
              'Lightning WebSocket ended. '
              'Code: $closeCode. Reason: $closeReason',
              name: 'LightningRepository',
            );

            if (!controller.isClosed && !isClosingIntentionally) {
              controller.addError(
                WebSocketException(
                  'The lightning connection was closed by the server. '
                  'Code: $closeCode. '
                  'Reason: ${closeReason ?? 'No reason provided.'}',
                ),
              );
            }
          },
          cancelOnError: false,
        );

        if (isDemoMode) {
          /*
           * Send the first simulated strike immediately.
           * The echo server sends it back through the WebSocket.
           */
          sendDemoStrike();

          demoTimer = Timer.periodic(_demoStrikeInterval, (_) {
            sendDemoStrike();
          });
        } else {
          /*
           * OpenWeather requires this exact plain-text subscription
           * message within 60 seconds.
           */
          connectedSocket.add('all_lightnings');

          developer.log(
            'Subscribed to all_lightnings.',
            name: 'LightningRepository',
          );
        }
      } on TimeoutException catch (error, stackTrace) {
        developer.log(
          'Lightning WebSocket connection timed out.',
          name: 'LightningRepository',
          error: error,
          stackTrace: stackTrace,
        );

        if (!controller.isClosed) {
          controller.addError(
            TimeoutException(
              'The lightning connection took too long.',
              _connectionTimeout,
            ),
            stackTrace,
          );
        }
      } on Object catch (error, stackTrace) {
        developer.log(
          'Could not connect to the lightning WebSocket.',
          name: 'LightningRepository',
          error: error,
          stackTrace: stackTrace,
        );

        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      } finally {
        isConnecting = false;
      }
    }

    controller = StreamController<LightningStrike>(
      onListen: () {
        unawaited(connect());
      },
      onPause: () {
        unawaited(closeSocket());
      },
      onResume: () {
        unawaited(connect());
      },
      onCancel: closeSocket,
    );

    return controller.stream;
  }

  LightningStrike? _tryParseDemoMessage(dynamic message) {
    final String messageText;

    if (message is String) {
      messageText = message;
    } else if (message is List<int>) {
      messageText = utf8.decode(message);
    } else {
      return null;
    }

    try {
      final dynamic decodedJson = jsonDecode(messageText);

      if (decodedJson is! Map<String, dynamic>) {
        return null;
      }

      /*
       * Ignore any JSON sent by the server that is not shaped like
       * our simulated lightning record.
       */
      if (!decodedJson.containsKey('id') ||
          !decodedJson.containsKey('date') ||
          !decodedJson.containsKey('lat') ||
          !decodedJson.containsKey('lon') ||
          !decodedJson.containsKey('error')) {
        return null;
      }

      return LightningStrike.fromJson(decodedJson);
    } on FormatException {
      return null;
    }
  }

  LightningStrike _parseMessage(dynamic message) {
    final String jsonText;

    if (message is String) {
      jsonText = message;
    } else if (message is List<int>) {
      jsonText = utf8.decode(message);
    } else {
      throw FormatException(
        'Unsupported WebSocket message type: '
        '${message.runtimeType}',
      );
    }

    final dynamic decodedJson = jsonDecode(jsonText);

    if (decodedJson is Map<String, dynamic>) {
      final String? serverError = _extractServerError(decodedJson);

      if (serverError != null) {
        throw WebSocketException(serverError);
      }

      return LightningStrike.fromJson(decodedJson);
    }

    throw const FormatException(
      'The lightning WebSocket returned an unexpected JSON structure.',
    );
  }

  String? _extractServerError(Map<String, dynamic> json) {
    final dynamic errorValue =
        json['message'] ?? json['errorMessage'] ?? json['error_message'];

    if (errorValue is String && errorValue.trim().isNotEmpty) {
      return errorValue.trim();
    }

    final dynamic typeValue =
        json['type'] ?? json['errorType'] ?? json['error_type'];

    if (typeValue is String) {
      final String errorType = typeValue.trim();

      const Set<String> knownErrors = {
        'APIKeyValidationError',
        'ExceededConnectionsLimitError',
        'Not supported streaming type',
      };

      if (knownErrors.contains(errorType)) {
        return errorType;
      }
    }

    return null;
  }
}
