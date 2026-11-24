import 'lightning_strike.dart';

class NearbyLightningStrike {
  const NearbyLightningStrike({
    required this.strike,
    required this.cityName,
    required this.distanceFromCityKm,
  });

  final LightningStrike strike;
  final String cityName;
  final double distanceFromCityKm;
}
