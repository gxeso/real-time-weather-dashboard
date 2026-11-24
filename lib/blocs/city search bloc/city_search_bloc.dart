import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/city_suggestion.dart';
import '../../repositories/city_repository.dart';
import 'city_search_event.dart';
import 'city_search_state.dart';

class CitySearchBloc extends Bloc<CitySearchEvent, CitySearchState> {
  CitySearchBloc({required CityRepository repository})
    : _repository = repository,
      super(const CitySearchInitial()) {
    on<CitySearchQueryChanged>(_onQueryChanged);
    on<CitySearchSubmitted>(_onSearchSubmitted);
    on<CitySearchCleared>(_onSearchCleared);
  }

  final CityRepository _repository;

  Timer? _debounceTimer;
  String _latestQuery = '';

  void _onQueryChanged(
    CitySearchQueryChanged event,
    Emitter<CitySearchState> emit,
  ) {
    _debounceTimer?.cancel();

    final String query = event.query.trim();
    _latestQuery = query;

    if (query.length < 2) {
      emit(const CitySearchInitial());
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      add(CitySearchSubmitted(query));
    });
  }

  Future<void> _onSearchSubmitted(
    CitySearchSubmitted event,
    Emitter<CitySearchState> emit,
  ) async {
    if (event.query != _latestQuery) {
      return;
    }

    emit(const CitySearchLoading());

    try {
      final List<CitySuggestion> suggestions = await _repository.searchCities(
        event.query,
      );

      if (event.query != _latestQuery) {
        return;
      }

      emit(CitySearchSuccess(suggestions));
    } on Object {
      if (event.query != _latestQuery) {
        return;
      }

      emit(const CitySearchError('Unable to search the local city list.'));
    }
  }

  void _onSearchCleared(
    CitySearchCleared event,
    Emitter<CitySearchState> emit,
  ) {
    _debounceTimer?.cancel();
    _latestQuery = '';

    emit(const CitySearchInitial());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
