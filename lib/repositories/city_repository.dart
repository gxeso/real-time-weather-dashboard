import 'dart:developer' as developer;

import 'package:flutter_country_state/complied_cities.dart';

import '../models/city_suggestion.dart';

class CityRepository {
  CityRepository() {
    _cities = _buildCityList();

    developer.log(
      'Loaded ${_cities.length} searchable cities.',
      name: 'CityRepository',
    );
  }

  static const int _maximumResults = 8;

  late final List<CitySuggestion> _cities;

  Future<List<CitySuggestion>> searchCities(String query) async {
    final String normalizedQuery = _normalize(query);

    if (normalizedQuery.length < 2) {
      return const [];
    }

    final List<_ScoredCity> matches = [];

    for (final CitySuggestion city in _cities) {
      final int? score = _calculateScore(query: normalizedQuery, city: city);

      if (score != null) {
        matches.add(_ScoredCity(city: city, score: score));
      }
    }

    matches.sort((_ScoredCity first, _ScoredCity second) {
      final int scoreComparison = first.score.compareTo(second.score);

      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return first.city.displayName.compareTo(second.city.displayName);
    });

    final List<CitySuggestion> results = matches
        .take(_maximumResults)
        .map((_ScoredCity match) => match.city)
        .toList(growable: false);

    developer.log(
      'City search "$query": '
      '${results.map((result) => result.displayName).join(' | ')}',
      name: 'CityRepository',
    );

    return results;
  }

  List<CitySuggestion> _buildCityList() {
    final List<CitySuggestion> cities = [];
    final Set<String> addedCities = {};

    for (final Object? countryObject in allStatesWithCities) {
      if (countryObject is! Map) {
        continue;
      }

      countryObject.forEach((dynamic countryKey, dynamic statesObject) {
        final String country = countryKey.toString().trim();

        if (country.isEmpty || statesObject is! Iterable) {
          return;
        }

        for (final dynamic stateObject in statesObject) {
          if (stateObject is! Map) {
            continue;
          }

          stateObject.forEach((dynamic stateKey, dynamic citiesObject) {
            final String state = stateKey.toString().trim();

            if (state.isEmpty) {
              return;
            }

            _addCitiesFromValue(
              value: citiesObject,
              state: state,
              country: country,
              cities: cities,
              addedCities: addedCities,
            );
          });
        }
      });
    }

    return List<CitySuggestion>.unmodifiable(cities);
  }

  void _addCitiesFromValue({
    required dynamic value,
    required String state,
    required String country,
    required List<CitySuggestion> cities,
    required Set<String> addedCities,
  }) {
    if (value is String) {
      _addCity(
        cityName: value,
        state: state,
        country: country,
        cities: cities,
        addedCities: addedCities,
      );

      return;
    }

    if (value is Iterable) {
      for (final dynamic item in value) {
        _addCitiesFromValue(
          value: item,
          state: state,
          country: country,
          cities: cities,
          addedCities: addedCities,
        );
      }

      return;
    }

    if (value is Map) {
      value.forEach((dynamic key, dynamic nestedValue) {
        /*
         * Support either:
         *
         * {cityName: ...}
         *
         * or nested collections containing city strings.
         */
        if (nestedValue == null || nestedValue is num || nestedValue is bool) {
          _addCity(
            cityName: key.toString(),
            state: state,
            country: country,
            cities: cities,
            addedCities: addedCities,
          );
          return;
        }

        _addCitiesFromValue(
          value: nestedValue,
          state: state,
          country: country,
          cities: cities,
          addedCities: addedCities,
        );
      });
    }
  }

  void _addCity({
    required String cityName,
    required String state,
    required String country,
    required List<CitySuggestion> cities,
    required Set<String> addedCities,
  }) {
    final String cleanCityName = cityName.trim();

    if (cleanCityName.isEmpty) {
      return;
    }

    final String uniqueKey = _normalize('$cleanCityName|$state|$country');

    if (!addedCities.add(uniqueKey)) {
      return;
    }

    cities.add(
      CitySuggestion(name: cleanCityName, state: state, country: country),
    );
  }

  int? _calculateScore({required String query, required CitySuggestion city}) {
    final String cityName = _normalize(city.name);
    final String stateName = _normalize(city.state);
    final String countryName = _normalize(city.country);

    // Exact match: "london".
    if (cityName == query) {
      return 0;
    }

    // Prefix match: "lon" finds "London".
    if (cityName.startsWith(query)) {
      return 10 + (cityName.length - query.length);
    }

    // Word-prefix match: "abu" finds "Abu Dhabi".
    final bool cityWordStartsWithQuery = cityName
        .split(' ')
        .any((String word) => word.startsWith(query));

    if (cityWordStartsWithQuery) {
      return 100 + (cityName.length - query.length).abs();
    }

    // Contains match.
    if (cityName.contains(query)) {
      return 200 + cityName.indexOf(query);
    }

    // Limited typo tolerance for city names.
    final int distance = _levenshteinDistance(query, cityName);

    final int maximumDistance;

    if (query.length <= 3) {
      maximumDistance = 1;
    } else if (query.length <= 6) {
      maximumDistance = 2;
    } else {
      maximumDistance = 3;
    }

    if (distance <= maximumDistance) {
      return 300 + (distance * 10) + (cityName.length - query.length).abs();
    }

    /*
     * State and country matching remains supported, but it has a
     * lower priority than matching an actual city name.
     */
    if (stateName == query) {
      return 400;
    }

    if (stateName.startsWith(query)) {
      return 410 + (stateName.length - query.length);
    }

    if (countryName == query) {
      return 500;
    }

    if (countryName.startsWith(query)) {
      return 510 + (countryName.length - query.length);
    }

    return null;
  }

  int _levenshteinDistance(String first, String second) {
    if (first == second) {
      return 0;
    }

    if (first.isEmpty) {
      return second.length;
    }

    if (second.isEmpty) {
      return first.length;
    }

    List<int> previousRow = List<int>.generate(
      second.length + 1,
      (int index) => index,
    );

    for (int firstIndex = 1; firstIndex <= first.length; firstIndex++) {
      final List<int> currentRow = List<int>.filled(second.length + 1, 0);

      currentRow[0] = firstIndex;

      for (int secondIndex = 1; secondIndex <= second.length; secondIndex++) {
        final int substitutionCost =
            first[firstIndex - 1] == second[secondIndex - 1] ? 0 : 1;

        final int deletion = previousRow[secondIndex] + 1;

        final int insertion = currentRow[secondIndex - 1] + 1;

        final int substitution =
            previousRow[secondIndex - 1] + substitutionCost;

        currentRow[secondIndex] = _minimumOfThree(
          deletion,
          insertion,
          substitution,
        );
      }

      previousRow = currentRow;
    }

    return previousRow[second.length];
  }

  int _minimumOfThree(int first, int second, int third) {
    int minimum = first;

    if (second < minimum) {
      minimum = second;
    }

    if (third < minimum) {
      minimum = third;
    }

    return minimum;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _ScoredCity {
  const _ScoredCity({required this.city, required this.score});

  final CitySuggestion city;
  final int score;
}
