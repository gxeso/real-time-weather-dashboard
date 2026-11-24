import '../../models/city_suggestion.dart';

sealed class CitySearchState {
  const CitySearchState();
}

final class CitySearchInitial extends CitySearchState {
  const CitySearchInitial();
}

final class CitySearchLoading extends CitySearchState {
  const CitySearchLoading();
}

final class CitySearchSuccess extends CitySearchState {
  const CitySearchSuccess(this.suggestions);

  final List<CitySuggestion> suggestions;
}

final class CitySearchError extends CitySearchState {
  const CitySearchError(this.message);

  final String message;
}
