sealed class CitySearchEvent {
  const CitySearchEvent();
}

final class CitySearchQueryChanged extends CitySearchEvent {
  const CitySearchQueryChanged(this.query);

  final String query;
}

final class CitySearchSubmitted extends CitySearchEvent {
  const CitySearchSubmitted(this.query);

  final String query;
}

final class CitySearchCleared extends CitySearchEvent {
  const CitySearchCleared();
}
