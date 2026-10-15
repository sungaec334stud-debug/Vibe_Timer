import 'package:flutter/material.dart';

import '../models/lab_phase.dart';
import '../theme/app_theme.dart';

/// Horizontally scrolling preset chips. Port of `PresetSelector.jsx`.
class PresetSelector extends StatelessWidget {
  const PresetSelector({
    super.key,
    required this.currentPresetId,
    required this.onSelectPreset,
  });

  final String currentPresetId;
  final ValueChanged<String> onSelectPreset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: kPresets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final StudyPreset preset = kPresets[index];
          final bool isActive = currentPresetId == preset.id;
          return _PresetChip(
            label: preset.label,
            isActive: isActive,
            onTap: () => onSelectPreset(preset.id),
          );
        },
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: const Cubic(0.16, 1, 0.3, 1),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? null
              : Colors.white.withValues(alpha: 0.04),
          gradient: isActive ? kPrimaryButtonGradient : null,
          border: Border.all(
            color: isActive
                ? AppColors.accentPurpleLight
                : AppColors.borderSubtle,
          ),
          borderRadius: BorderRadius.circular(AppRadii.full),
          boxShadow: isActive
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.accentPurpleGlow,
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12.8,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}