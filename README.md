# Real-Time Weather Dashboard

A Flutter weather application that combines current weather information, offline city search, and live lightning updates through a structured BLoC and repository architecture.

## Features

- Current weather conditions
- City search and suggestions
- Offline city-search support
- Live lightning-strike updates
- Distance calculation for nearby lightning
- Automatic weather polling
- WebSocket connection monitoring
- Automatic reconnection handling
- Application lifecycle management
- Light and dark themes
- Loading, connected, disconnected, and error states

## Architecture

The project uses BLoC to separate the interface from application logic.

Main components include:

- **Weather BLoC** — controls weather requests and states
- **Lightning BLoC** — processes live WebSocket updates
- **City Search BLoC** — manages city suggestions and filtering
- **Theme BLoC** — controls the application theme
- **Repositories** — abstract weather, lightning, and city data
- **Lifecycle coordinator** — safely starts and stops live operations

## Technologies

- Flutter
- Dart
- BLoC
- REST APIs
- WebSockets
- Repository pattern
- Flutter DevTools

## Getting Started

Configure the required weather and lightning data providers, then run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Reliability

The application detects interrupted WebSocket connections and attempts to reconnect safely. Active timers, subscriptions, and network operations are managed according to the Flutter application lifecycle.

## What I Learned

This project strengthened my understanding of BLoC state management, REST and WebSocket communication, stream subscriptions, connection recovery, lifecycle safety, repository abstraction, and real-time application profiling.
