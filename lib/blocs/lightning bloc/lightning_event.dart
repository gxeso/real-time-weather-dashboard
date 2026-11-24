abstract class LightningEvent {
  const LightningEvent();
}

final class LightningStarted extends LightningEvent {
  const LightningStarted();
}

final class LightningLocationChanged extends LightningEvent {
  const LightningLocationChanged({
    required this.cityName,
    required this.latitude,
    required this.longitude,
  });

  final String cityName;
  final double latitude;
  final double longitude;
}

final class LightningPaused extends LightningEvent {
  const LightningPaused();
}

final class LightningResumed extends LightningEvent {
  const LightningResumed();
}

final class LightningRetried extends LightningEvent {
  const LightningRetried();
}
