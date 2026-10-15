import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The pill toast that slides in under the header. Port of `.mobile-toast`.
class ToastBanner extends StatelessWidget {
  const ToastBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(message),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.bgCardElevated,
            borderRadius: BorderRadius.circular(AppRadii.full),
            border: Border.all(color: AppColors.accentPurple),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            '⚡ $message',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12.8,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}