import 'package:flutter/material.dart';

import '../models/study_models.dart';
import '../theme/app_theme.dart';

/// Focus minutes / sessions / prompts summary row.
/// Port of `SessionStats.jsx`.
class SessionStatsBar extends StatelessWidget {
  const SessionStatsBar({super.key, required this.stats});

  final StudyStats stats;

  @override
  Widget build(BuildContext context) {
    final int totalMins = stats.totalMinutes;
    final int hrs = totalMins ~/ 60;
    final int remaining = totalMins % 60;
    final String timeFormatted =
        hrs > 0 ? '$hrs h $remaining m' : '$totalMins m';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: <Widget>[
          _Metric(
            label: 'Total Focus',
            value: timeFormatted,
            valueColor: Colors.white,
          ),
          _Metric(
            label: 'Sessions',
            value: '${stats.totalSessions}',
            valueColor: AppColors.accentPurpleLight,
          ),
          _Metric(
            label: 'Prompts Logged',
            value: '${stats.totalPrompts}',
            valueColor: AppColors.accentCyan,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 10.9,
              fontWeight: FontWeight.w600,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 18.4,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}