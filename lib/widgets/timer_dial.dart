import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lab_phase.dart';
import '../theme/app_theme.dart';

/// Circular progress ring + countdown digits.
///
/// Flutter port of `TimerDial.jsx` and the `.mobile-timer-dial` /
/// `.dial-*` rules in `styles/timer.css`.
class TimerDial extends StatelessWidget {
  const TimerDial({
    super.key,
    required this.timeFormatted,
    required this.progressFraction,
    required this.isRunning,
    required this.presetId,
    required this.phase,
  });

  final String timeFormatted;
  final double progressFraction;
  final bool isRunning;
  final String presetId;
  final LabPhase? phase;

  static const double size = 270;
  static const double strokeWidth = 12;

  @override
  Widget build(BuildContext context) {
    final ({String label, String tip}) copy = stageCopyFor(presetId, phase);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progressFraction.clamp(0, 1)),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (BuildContext context, double value, _) {
              return SizedBox.expand(
                child: CustomPaint(
                  painter: _DialPainter(
                    progress: value,
                    isRunning: isRunning,
                  ),
                ),
              );
            },
          ),
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 42),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    timeFormatted,
                    style: AppTextStyles.display,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.accentPurple),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(
                      copy.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.monoSmall,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    copy.tip,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.progress, required this.isRunning});

  final double progress;
  final bool isRunning;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius =
        (math.min(size.width, size.height) - TimerDial.strokeWidth) / 2;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    // Background track (.dial-bg-ring)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = TimerDial.strokeWidth
        ..color = Colors.white.withValues(alpha: 0.05),
    );

    if (progress <= 0) return;

    // Animated progress ring (.dial-progress-ring) with the same
    // purple → cyan gradient the SVG used.
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = TimerDial.strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: (3 * math.pi) / 2,
        colors: const <Color>[
          AppColors.accentPurple,
          AppColors.accentPurpleLight,
          AppColors.accentCyan,
        ],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(arcRect);

    canvas.drawArc(arcRect, -math.pi / 2, 2 * math.pi * progress, false, ring);

    // Pulsing glow while running (.is-running-glow)
    if (isRunning) {
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = TimerDial.strokeWidth + 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
          ..shader = SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: (3 * math.pi) / 2,
            colors: <Color>[
              AppColors.accentPurple.withValues(alpha: 0.35),
              AppColors.accentCyan.withValues(alpha: 0.35),
            ],
            transform: const GradientRotation(-math.pi / 2),
          ).createShader(arcRect),
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRunning != isRunning;
  }
}