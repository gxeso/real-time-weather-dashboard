import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weather_dashboard/screens/widgets/lightning_status_card.dart';

import '../blocs/city search bloc/city_search_bloc.dart';
import '../blocs/city search bloc/city_search_event.dart';
import '../blocs/city search bloc/city_search_state.dart';
import '../blocs/theme bloc/theme_bloc.dart';
import '../blocs/theme bloc/theme_event.dart';
import '../blocs/theme bloc/theme_state.dart';
import '../blocs/weather logic bloc/weather_bloc.dart';
import '../blocs/weather logic bloc/weather_event.dart';
import '../blocs/weather logic bloc/weather_state.dart';
import '../models/city_suggestion.dart';
import '../models/weather_data.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with WidgetsBindingObserver {
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    context.read<WeatherBloc>().add(const WeatherStarted('Dubai'));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      context.read<WeatherBloc>().add(const WeatherPaused());
    }

    if (state == AppLifecycleState.resumed) {
      context.read<WeatherBloc>().add(const WeatherResumed());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cityController.dispose();

    super.dispose();
  }

  void _searchCity() {
    final String city = _cityController.text.trim();

    context.read<CitySearchBloc>().add(const CitySearchCleared());

    context.read<WeatherBloc>().add(WeatherCityChanged(city));

    FocusScope.of(context).unfocus();
  }

  void _selectCity(CitySuggestion suggestion) {
    _cityController.value = TextEditingValue(
      text: suggestion.displayName,
      selection: TextSelection.collapsed(offset: suggestion.displayName.length),
    );

    context.read<CitySearchBloc>().add(const CitySearchCleared());

    context.read<WeatherBloc>().add(
      WeatherCityChanged(suggestion.weatherQuery),
    );

    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: context.isDarkMode
                ? const [
                    Color(0xFF101827),
                    Color(0xFF17233A),
                    Color(0xFF0C1220),
                  ]
                : const [
                    Color(0xFFF8FBFF),
                    Color(0xFFEAF4FB),
                    Color(0xFFF4F8FC),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      _buildSearchBar(),
                      _buildCitySuggestions(),
                      const SizedBox(height: 24),
                      BlocBuilder<WeatherBloc, WeatherState>(
                        builder: (context, state) {
                          return switch (state) {
                            WeatherInitial() => const SizedBox.shrink(),
                            WeatherLoading(:final city) => _LoadingView(
                              city: city,
                            ),
                            WeatherLoaded(:final weather) => _WeatherView(
                              weather: weather,
                            ),
                            WeatherError(:final city, :final message) =>
                              _ErrorView(city: city, message: message),
                          };
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.cloud_outlined, color: colors.primary, size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weather Dashboard',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                'Live conditions updated automatically',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return IconButton(
              onPressed: () {
                context.read<ThemeBloc>().add(const ThemeToggled());
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  themeState.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  key: ValueKey<bool>(themeState.isDarkMode),
                  color: themeState.isDarkMode
                      ? const Color(0xFFFFD166)
                      : colors.primary,
                ),
              ),
              tooltip: themeState.isDarkMode
                  ? 'Switch to light mode'
                  : 'Switch to dark mode',
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return TextField(
      controller: _cityController,
      textInputAction: TextInputAction.search,
      onChanged: (String query) {
        context.read<CitySearchBloc>().add(CitySearchQueryChanged(query));
      },
      onSubmitted: (_) => _searchCity(),
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        hintText: 'Start typing a city',
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        prefixIcon: Icon(Icons.location_city, color: colors.primary),
        suffixIcon: IconButton(
          onPressed: _searchCity,
          icon: const Icon(Icons.search),
          color: colors.onSurface,
          tooltip: 'Search',
        ),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCitySuggestions() {
    return BlocBuilder<CitySearchBloc, CitySearchState>(
      builder: (context, state) {
        return switch (state) {
          CitySearchInitial() => const SizedBox.shrink(),
          CitySearchLoading() => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHigh,
            ),
          ),
          CitySearchSuccess(:final suggestions) => _CitySuggestionsPanel(
            suggestions: suggestions,
            onSelected: _selectCity,
          ),
          CitySearchError(:final message) => Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        };
      },
    );
  }
}

class _CitySuggestionsPanel extends StatelessWidget {
  const _CitySuggestionsPanel({
    required this.suggestions,
    required this.onSelected,
  });

  final List<CitySuggestion> suggestions;
  final ValueChanged<CitySuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'No matching cities found.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) {
          return Divider(height: 1, color: colors.outlineVariant);
        },
        itemBuilder: (context, index) {
          final CitySuggestion suggestion = suggestions[index];

          return ListTile(
            onTap: () => onSelected(suggestion),
            leading: Icon(Icons.location_on_outlined, color: colors.primary),
            title: Text(
              suggestion.name,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _buildSubtitle(suggestion),
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            trailing: Icon(
              Icons.north_west,
              color: colors.onSurfaceVariant,
              size: 18,
            ),
          );
        },
      ),
    );
  }

  String _buildSubtitle(CitySuggestion suggestion) {
    final List<String> parts = [];

    if (suggestion.state.isNotEmpty) {
      parts.add(suggestion.state);
    }

    parts.add(suggestion.country);

    return parts.join(', ');
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colors.primary),
          const SizedBox(height: 20),
          Text(
            'Loading weather for $city...',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurface, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _WeatherView extends StatelessWidget {
  const _WeatherView({required this.weather});

  final WeatherData weather;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WeatherSummaryCard(weather: weather),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _WeatherDetailCard(
                icon: Icons.water_drop_outlined,
                label: 'Humidity',
                value: '${weather.humidity}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WeatherDetailCard(
                icon: Icons.air,
                label: 'Wind speed',
                value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _WeatherDetailCard(
                icon: Icons.thermostat,
                label: 'Feels like',
                value: '${weather.feelsLike.toStringAsFixed(1)}°C',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WeatherDetailCard(
                icon: Icons.schedule,
                label: 'Last updated',
                value: _formatTime(weather.lastUpdated),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Live lightning WebSocket information.
        const LightningStatusCard(),

        const SizedBox(height: 20),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');

    final String minute = dateTime.minute.toString().padLeft(2, '0');

    final String second = dateTime.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second';
  }
}

class _WeatherSummaryCard extends StatelessWidget {
  const _WeatherSummaryCard({required this.weather});

  final WeatherData weather;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            weather.cityName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Image.network(
            'https://openweathermap.org/img/wn/'
            '${weather.icon}@4x.png',
            width: 130,
            height: 130,
            errorBuilder: (context, error, stackTrace) {
              return SizedBox(
                width: 130,
                height: 130,
                child: Icon(
                  Icons.cloud_outlined,
                  color: colors.primary,
                  size: 82,
                ),
              );
            },
          ),
          Text(
            '${weather.temperature.toStringAsFixed(1)}°C',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 58,
              fontWeight: FontWeight.w300,
              height: 1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _formatCondition(weather.condition),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.circle, color: Color(0xFF20B486), size: 9),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Live updates every 10 seconds',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatCondition(String condition) {
  return condition
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

class _WeatherDetailCard extends StatelessWidget {
  const _WeatherDetailCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(height: 20),
          Text(
            label,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.city, required this.message});

  final String city;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.errorContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.error),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, color: colors.error, size: 52),
              const SizedBox(height: 16),
              Text(
                city.isEmpty
                    ? 'Unable to load weather'
                    : 'Unable to load $city',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onErrorContainer,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onErrorContainer,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  context.read<WeatherBloc>().add(const WeatherRetried());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
