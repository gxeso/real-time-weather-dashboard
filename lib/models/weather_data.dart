class WeatherData {
  const WeatherData({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.feelsLike,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
  });

  final String cityName;
  final double temperature;
  final String condition;
  final String icon;
  final int humidity;
  final double windSpeed;
  final double feelsLike;

  /// Latitude of the location returned by OpenWeather.
  final double latitude;

  /// Longitude of the location returned by OpenWeather.
  final double longitude;

  /// Time at which this application received and parsed the weather.
  final DateTime lastUpdated;

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> mainData = _readRequiredMap(
      json: json,
      key: 'main',
    );

    final Map<String, dynamic> windData = _readRequiredMap(
      json: json,
      key: 'wind',
    );

    final Map<String, dynamic> coordinateData = _readRequiredMap(
      json: json,
      key: 'coord',
    );

    final List<dynamic> weatherList = _readRequiredList(
      json: json,
      key: 'weather',
    );

    if (weatherList.isEmpty || weatherList.first is! Map<String, dynamic>) {
      throw const FormatException(
        'The weather information is missing or invalid.',
      );
    }

    final Map<String, dynamic> weatherData =
        weatherList.first as Map<String, dynamic>;

    return WeatherData(
      cityName: _readRequiredString(json: json, key: 'name'),
      temperature: _readRequiredDouble(json: mainData, key: 'temp'),
      condition: _readRequiredString(json: weatherData, key: 'description'),
      icon: _readRequiredString(json: weatherData, key: 'icon'),
      humidity: _readRequiredInt(json: mainData, key: 'humidity'),
      windSpeed: _readRequiredDouble(json: windData, key: 'speed'),
      feelsLike: _readRequiredDouble(json: mainData, key: 'feels_like'),
      latitude: _readRequiredDouble(json: coordinateData, key: 'lat'),
      longitude: _readRequiredDouble(json: coordinateData, key: 'lon'),
      lastUpdated: DateTime.now(),
    );
  }

  static Map<String, dynamic> _readRequiredMap({
    required Map<String, dynamic> json,
    required String key,
  }) {
    final dynamic value = json[key];

    if (value is Map<String, dynamic>) {
      return value;
    }

    throw FormatException('Weather field "$key" must be a JSON object.');
  }

  static List<dynamic> _readRequiredList({
    required Map<String, dynamic> json,
    required String key,
  }) {
    final dynamic value = json[key];

    if (value is List<dynamic>) {
      return value;
    }

    throw FormatException('Weather field "$key" must be a JSON list.');
  }

  static String _readRequiredString({
    required Map<String, dynamic> json,
    required String key,
  }) {
    final dynamic value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Weather field "$key" must be a non-empty string.');
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

    throw FormatException('Weather field "$key" must be a number.');
  }

  static int _readRequiredInt({
    required Map<String, dynamic> json,
    required String key,
  }) {
    final dynamic value = json[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final int? parsedValue = int.tryParse(value);

      if (parsedValue != null) {
        return parsedValue;
      }
    }

    throw FormatException('Weather field "$key" must be an integer.');
  }
}
