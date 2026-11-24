class CitySuggestion {
  const CitySuggestion({
    required this.name,
    required this.country,
    required this.state,
  });

  final String name;
  final String country;
  final String state;

  String get displayName {
    final List<String> parts = [name, if (state.isNotEmpty) state, country];

    return parts.join(', ');
  }

  /*
   * OpenWeather's direct city lookup is most reliable when the
   * actual city name is supplied. The package contains full country
   * and region names rather than ISO country/state codes.
   */
  String get weatherQuery => name;
}
