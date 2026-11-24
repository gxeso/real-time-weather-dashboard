import 'dart:math' as math;

class DistanceCalculator {
  const DistanceCalculator._();

  /// Mean radius of Earth in kilometres.
  static const double _earthRadiusKm = 6371;

  static double calculateHaversineDistanceKm({
    required double firstLatitude,
    required double firstLongitude,
    required double secondLatitude,
    required double secondLongitude,
  }) {
    _validateCoordinates(
      latitude: firstLatitude,
      longitude: firstLongitude,
      label: 'First location',
    );

    _validateCoordinates(
      latitude: secondLatitude,
      longitude: secondLongitude,
      label: 'Second location',
    );

    final double firstLatitudeRadians = _degreesToRadians(firstLatitude);

    final double secondLatitudeRadians = _degreesToRadians(secondLatitude);

    final double latitudeDifferenceRadians = _degreesToRadians(
      secondLatitude - firstLatitude,
    );

    final double longitudeDifferenceRadians = _degreesToRadians(
      secondLongitude - firstLongitude,
    );

    final double latitudeComponent = math.sin(latitudeDifferenceRadians / 2);

    final double longitudeComponent = math.sin(longitudeDifferenceRadians / 2);

    final double haversineValue =
        (latitudeComponent * latitudeComponent) +
        math.cos(firstLatitudeRadians) *
            math.cos(secondLatitudeRadians) *
            (longitudeComponent * longitudeComponent);

    /*
     * Floating-point calculations can occasionally produce a value
     * slightly below 0 or above 1. Clamping prevents invalid square roots.
     */
    final double safeHaversineValue = haversineValue.clamp(0.0, 1.0).toDouble();

    final double angularDistance =
        2 *
        math.atan2(
          math.sqrt(safeHaversineValue),
          math.sqrt(1 - safeHaversineValue),
        );

    return _earthRadiusKm * angularDistance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  static void _validateCoordinates({
    required double latitude,
    required double longitude,
    required String label,
  }) {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        '$label latitude must be between -90 and 90.',
      );
    }

    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        '$label longitude must be between -180 and 180.',
      );
    }
  }
}
