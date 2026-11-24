import 'package:weather_dashboard/models/nearby_lightning_strike.dart';

sealed class LightningState {
  const LightningState();
}

final class LightningInitial extends LightningState {
  const LightningInitial();
}

final class LightningConnecting extends LightningState {
  const LightningConnecting({
    required this.cityName,
    required this.latestNearbyStrike,
    required this.nearbyStrikeCount,
  });

  final String? cityName;
  final NearbyLightningStrike? latestNearbyStrike;
  final int nearbyStrikeCount;
}

final class LightningLive extends LightningState {
  const LightningLive({
    required this.latestNearbyStrike,
    required this.nearbyStrikeCount,
  });

  final NearbyLightningStrike latestNearbyStrike;
  final int nearbyStrikeCount;
}

final class LightningPausedState extends LightningState {
  const LightningPausedState({
    required this.cityName,
    required this.latestNearbyStrike,
    required this.nearbyStrikeCount,
  });

  final String? cityName;
  final NearbyLightningStrike? latestNearbyStrike;
  final int nearbyStrikeCount;
}

final class LightningFailure extends LightningState {
  const LightningFailure({
    required this.message,
    required this.cityName,
    required this.latestNearbyStrike,
    required this.nearbyStrikeCount,
  });

  final String message;
  final String? cityName;
  final NearbyLightningStrike? latestNearbyStrike;
  final int nearbyStrikeCount;
}
