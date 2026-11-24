enum LightningQuality {
  good,
  medium,
  bad,
  undefined;

  static LightningQuality fromJson(dynamic value) {
    final String normalizedValue = value?.toString().trim().toLowerCase() ?? '';

    return switch (normalizedValue) {
      'good' => LightningQuality.good,
      'medium' => LightningQuality.medium,
      'bad' => LightningQuality.bad,
      _ => LightningQuality.undefined,
    };
  }
}

class LightningStrike {
  const LightningStrike({
    required this.id,
    required this.detectedAt,
    required this.latitude,
    required this.longitude,
    required this.quality,
    required this.locationUncertaintyKm,
  });

  final String id;
  final DateTime detectedAt;
  final double latitude;
  final double longitude;
  final LightningQuality quality;

  /// Estimated horizontal location uncertainty in kilometres.
  final double locationUncertaintyKm;

  factory LightningStrike.fromJson(Map<String, dynamic> json) {
    final String id = _readRequiredString(json: json, key: 'id');

    final double latitude = _readRequiredDouble(json: json, key: 'lat');

    final double longitude = _readRequiredDouble(json: json, key: 'lon');

    final double locationUncertaintyKm = _readRequiredDouble(
      json: json,
      key: 'error',
    );

    final DateTime detectedAt = _parseUtcDate(json['date']);

    if (latitude < -90 || latitude > 90) {
      throw const FormatException(
        'Lightning latitude must be between -90 and 90.',
      );
    }

    if (longitude < -180 || longitude > 180) {
      throw const FormatException(
        'Lightning longitude must be between -180 and 180.',
      );
    }

    if (locationUncertaintyKm < 0) {
      throw const FormatException(
        'Lightning location uncertainty cannot be negative.',
      );
    }

    return LightningStrike(
      id: id,
      detectedAt: detectedAt,
      latitude: latitude,
      longitude: longitude,
      quality: LightningQuality.fromJson(json['quality']),
      locationUncertaintyKm: locationUncertaintyKm,
    );
  }

  static String _readRequiredString({
    required Map<String, dynamic> json,
    required String key,
  }) {
    final dynamic value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'Lightning field "$key" must be a non-empty string.',
      );
    }

    return value.trim();
  }

  static double _readRequiredDouble({
    required Map<String, dynamic> json,
    required String key,
  }) {
    final dynamic value = json[key];

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final double? parsedValue = double.tryParse(value);

      if (parsedValue != null) {
        return parsedValue;
      }
    }

    throw FormatException('Lightning field "$key" must be a number.');
  }

  static DateTime _parseUtcDate(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException(
        'Lightning field "date" must be a non-empty string.',
      );
    }

    final String dateValue = value.trim();

    // First support the ISO-8601 format described by the documentation.
    final DateTime? isoDate = DateTime.tryParse(dateValue);

    if (isoDate != null) {
      return isoDate.toUtc();
    }

    /*
     * The OpenWeather example currently uses:
     *
     * 07/08/2026 13:50:47
     *
     * We treat this as day/month/year and construct a UTC DateTime.
     */
    final RegExp legacyDatePattern = RegExp(
      r'^(\d{2})/(\d{2})/(\d{4}) '
      r'(\d{2}):(\d{2}):(\d{2})$',
    );

    final RegExpMatch? match = legacyDatePattern.firstMatch(dateValue);

    if (match == null) {
      throw FormatException('Unsupported lightning date format: $dateValue');
    }

    final int day = int.parse(match.group(1)!);
    final int month = int.parse(match.group(2)!);
    final int year = int.parse(match.group(3)!);
    final int hour = int.parse(match.group(4)!);
    final int minute = int.parse(match.group(5)!);
    final int second = int.parse(match.group(6)!);

    final DateTime result = DateTime.utc(
      year,
      month,
      day,
      hour,
      minute,
      second,
    );

    /*
     * DateTime can normalize invalid dates. For example, day 40 could
     * overflow into another month. This verifies that normalization did
     * not happen.
     */
    if (result.year != year ||
        result.month != month ||
        result.day != day ||
        result.hour != hour ||
        result.minute != minute ||
        result.second != second) {
      throw FormatException('Invalid lightning date: $dateValue');
    }

    return result;
  }
}
