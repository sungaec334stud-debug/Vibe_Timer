import 'package:flutter/material.dart';

import '../models/lab_phase.dart';
import '../theme/app_theme.dart';

/// The 4-stage 60-minute lab tracker. Port of `LabRoadmap.jsx`.
class LabRoadmap extends StatelessWidget {
  const LabRoadmap({
    super.key,
    required this.currentPhaseIndex,
    required this.isLabActive,
  });

  final int currentPhaseIndex;
  final bool isLabActive;

  @override
  Widget build(BuildContext context) {
    if (!isLabActive) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Text('⚡', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(
                    '60-Min Vibe Lab Roadmap',
                    style: AppTextStyles.cardTitle,
                  ),
                ],
              ),
              Text(
                'SLIDE 15',
                style: AppTextStyles.monoSmall.copyWith(fontSize: 11.2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < kLabPhases.length; i++) ...<Widget>[
            _RoadmapStep(
              phase: kLabPhases[i],
              index: i,
              isActive: i == currentPhaseIndex,
              isCompleted: i < currentPhaseIndex,
            ),
            if (i != kLabPhases.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _RoadmapStep extends StatelessWidget {
  const _RoadmapStep({
    required this.phase,
    required this.index,
    required this.isActive,
    required this.isCompleted,
  });

  final LabPhase phase;
  final int index;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.accentPurple.withValues(alpha: 0.14)
            : isCompleted
                ? AppColors.success.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isActive
              ? AppColors.accentPurple
              : isCompleted
                  ? AppColors.success.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.04),
        ),
        boxShadow: isActive
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColors.accentPurple.withValues(alpha: 0.25),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.accentPurple
                  : isCompleted
                      ? AppColors.success
                      : Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? <BoxShadow>[
                      BoxShadow(
                        color: AppColors.accentPurpleGlow,
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              isCompleted ? '✓' : '0${index + 1}',
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 11.2,
                fontWeight: FontWeight.w700,
                color: isActive || isCompleted
                    ? Colors.white
                    : AppColors.textDim,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      phase.title,
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13.6,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      phase.timeTag,
                      style: const TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 11.2,
                        color: AppColors.accentCyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(phase.tip, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}