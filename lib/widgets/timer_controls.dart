import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Start/Pause, Next phase and Reset. Port of `TimerControls.jsx`.
class TimerControls extends StatelessWidget {
  const TimerControls({
    super.key,
    required this.isRunning,
    required this.onToggle,
    required this.onReset,
    required this.onSkipPhase,
    required this.showSkipPhase,
  });

  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final VoidCallback onSkipPhase;
  final bool showSkipPhase;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: _PrimaryButton(
            icon: isRunning
                ? const Icon(
                    Icons.pause_rounded,
                    size: 18,
                    color: Colors.white,
                  )
                : const Icon(
                    Icons.play_arrow_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
            label: isRunning ? 'Pause' : 'Start',
            onPressed: onToggle,
          ),
        ),
        if (showSkipPhase) ...<Widget>[
          const SizedBox(width: 10),
          Expanded(
            child: _SecondaryButton(
              icon: const Icon(Icons.skip_next_rounded, size: 16),
              label: 'Next',
              onPressed: onSkipPhase,
            ),
          ),
        ],
        const SizedBox(width: 10),
        Expanded(
          child: _SecondaryButton(
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: 'Reset',
            onPressed: onReset,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: kPrimaryButtonGradient,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.accentPurpleGlow,
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.full),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                icon,
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppFonts.main,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      shape: StadiumBorder(
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconTheme(
                data: const IconThemeData(color: AppColors.textSecondary),
                child: icon,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 13.6,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}