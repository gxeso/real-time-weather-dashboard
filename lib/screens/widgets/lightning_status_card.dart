import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/lightning bloc/lightning_bloc.dart';
import '../../blocs/lightning bloc/lightning_event.dart';
import '../../blocs/lightning bloc/lightning_state.dart';
import '../../models/lightning_strike.dart';
import '../../models/nearby_lightning_strike.dart';

class LightningStatusCard extends StatelessWidget {
  const LightningStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LightningBloc, LightningState>(
      builder: (BuildContext context, LightningState state) {
        return switch (state) {
          LightningInitial() => const _LightningCardShell(
            icon: Icons.bolt_outlined,
            iconColor: Color(0xFFFFD166),
            title: 'Live lightning',
            message: 'Preparing the lightning stream...',
          ),
          LightningConnecting(
            :final cityName,
            :final latestNearbyStrike,
            :final nearbyStrikeCount,
          ) =>
            _buildConnectingCard(
              cityName: cityName,
              latestStrike: latestNearbyStrike,
              nearbyStrikeCount: nearbyStrikeCount,
            ),
          LightningLive(:final latestNearbyStrike, :final nearbyStrikeCount) =>
            _LiveLightningCard(
              nearbyStrike: latestNearbyStrike,
              nearbyStrikeCount: nearbyStrikeCount,
            ),
          LightningPausedState(
            :final cityName,
            :final latestNearbyStrike,
            :final nearbyStrikeCount,
          ) =>
            _buildPausedCard(
              cityName: cityName,
              latestStrike: latestNearbyStrike,
              nearbyStrikeCount: nearbyStrikeCount,
            ),
          LightningFailure(
            :final message,
            :final latestNearbyStrike,
            :final nearbyStrikeCount,
          ) =>
            _LightningFailureCard(
              message: message,
              latestStrike: latestNearbyStrike,
              nearbyStrikeCount: nearbyStrikeCount,
            ),
        };
      },
    );
  }

  Widget _buildConnectingCard({
    required String? cityName,
    required NearbyLightningStrike? latestStrike,
    required int nearbyStrikeCount,
  }) {
    final String message = cityName == null
        ? 'Waiting for the selected city...'
        : 'Monitoring within '
              '${LightningBloc.nearbyRadiusKm.toStringAsFixed(0)} km '
              'of $cityName';

    return _LightningCardShell(
      icon: Icons.bolt_outlined,
      iconColor: const Color(0xFFFFD166),
      title: 'Connecting to live lightning',
      message: message,
      trailing: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFFFD166),
        ),
      ),
      footer: latestStrike == null
          ? null
          : _PreviousStrikeSummary(
              strike: latestStrike,
              count: nearbyStrikeCount,
            ),
    );
  }

  Widget _buildPausedCard({
    required String? cityName,
    required NearbyLightningStrike? latestStrike,
    required int nearbyStrikeCount,
  }) {
    return _LightningCardShell(
      icon: Icons.pause_circle_outline,
      iconColor: const Color(0xFF9EACC4),
      title: 'Lightning monitoring paused',
      message: cityName == null
          ? 'Monitoring resumes when the app returns.'
          : 'Monitoring near $cityName resumes when the app returns.',
      footer: latestStrike == null
          ? null
          : _PreviousStrikeSummary(
              strike: latestStrike,
              count: nearbyStrikeCount,
            ),
    );
  }
}

class _LiveLightningCard extends StatelessWidget {
  const _LiveLightningCard({
    required this.nearbyStrike,
    required this.nearbyStrikeCount,
  });

  final NearbyLightningStrike nearbyStrike;
  final int nearbyStrikeCount;

  @override
  Widget build(BuildContext context) {
    final LightningStrike strike = nearbyStrike.strike;

    return _LightningCardShell(
      icon: Icons.bolt,
      iconColor: const Color(0xFFFFD166),
      title: 'Nearby lightning detected',
      message:
          '${nearbyStrike.distanceFromCityKm.toStringAsFixed(1)} km '
          'from ${nearbyStrike.cityName}',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _qualityColor(strike.quality).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _qualityLabel(strike.quality),
          style: TextStyle(
            color: _qualityColor(strike.quality),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      footer: Wrap(
        spacing: 18,
        runSpacing: 10,
        children: [
          _LightningInformation(
            icon: Icons.schedule,
            label: _formatTime(strike.detectedAt),
          ),
          _LightningInformation(
            icon: Icons.radar,
            label: '±${strike.locationUncertaintyKm.toStringAsFixed(1)} km',
          ),
          _LightningInformation(
            icon: Icons.numbers,
            label: '$nearbyStrikeCount nearby',
          ),
        ],
      ),
    );
  }

  Color _qualityColor(LightningQuality quality) {
    return switch (quality) {
      LightningQuality.good => const Color(0xFF64FFDA),
      LightningQuality.medium => const Color(0xFFFFD166),
      LightningQuality.bad => const Color(0xFFFF8A9B),
      LightningQuality.undefined => const Color(0xFF9EACC4),
    };
  }

  String _qualityLabel(LightningQuality quality) {
    return switch (quality) {
      LightningQuality.good => 'Good quality',
      LightningQuality.medium => 'Medium quality',
      LightningQuality.bad => 'Low quality',
      LightningQuality.undefined => 'Unknown quality',
    };
  }

  String _formatTime(DateTime dateTime) {
    final DateTime localTime = dateTime.toLocal();

    final String hour = localTime.hour.toString().padLeft(2, '0');
    final String minute = localTime.minute.toString().padLeft(2, '0');
    final String second = localTime.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second';
  }
}

class _LightningFailureCard extends StatelessWidget {
  const _LightningFailureCard({
    required this.message,
    required this.latestStrike,
    required this.nearbyStrikeCount,
  });

  final String message;
  final NearbyLightningStrike? latestStrike;
  final int nearbyStrikeCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return _LightningCardShell(
      icon: Icons.bolt_outlined,
      iconColor: colors.error,
      title: 'Lightning stream unavailable',
      message: message,
      trailing: TextButton.icon(
        onPressed: () {
          context.read<LightningBloc>().add(const LightningRetried());
        },
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Retry'),
        style: TextButton.styleFrom(foregroundColor: colors.primary),
      ),
      footer: latestStrike == null
          ? null
          : _PreviousStrikeSummary(
              strike: latestStrike!,
              count: nearbyStrikeCount,
            ),
    );
  }
}

class _PreviousStrikeSummary extends StatelessWidget {
  const _PreviousStrikeSummary({required this.strike, required this.count});

  final NearbyLightningStrike strike;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Text(
      'Previous nearby strike: '
      '${strike.distanceFromCityKm.toStringAsFixed(1)} km away'
      ' • $count received',
      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
    );
  }
}

class _LightningInformation extends StatelessWidget {
  const _LightningInformation({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}

class _LightningCardShell extends StatelessWidget {
  const _LightningCardShell({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.trailing,
    this.footer,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 16),
            Divider(color: colors.outlineVariant, height: 1),
            const SizedBox(height: 14),
            footer!,
          ],
        ],
      ),
    );
  }
}
