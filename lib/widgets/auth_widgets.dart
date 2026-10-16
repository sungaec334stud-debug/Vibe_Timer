import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Gradient pill CTA — the same shape as `_ActionButton` in
/// `custom_timer_sheet.dart`, lifted here so the auth screens share it.
///
/// Supports a busy state because every auth submit is network-bound and needs
/// to be visibly disabled.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.isBusy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isBusy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isBusy;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.05),
          gradient: isPrimary ? kPrimaryButtonGradient : null,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: isPrimary
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: isPrimary
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.accentPurpleGlow,
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Center(
                child: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (icon != null) ...<Widget>[
                            Icon(
                              icon,
                              size: 18,
                              color: isPrimary
                                  ? Colors.white
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 15.2,
                              fontWeight: isPrimary
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color:
                                  isPrimary ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Labelled input. Styling comes from the global `inputDecorationTheme`, so
/// this only adds the label, icon and field-level error line.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.onSubmitted,
    this.errorText,
    this.autofocus = false,
  });

  final String label;
  final String? hint;
  final IconData? icon;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 10.4,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.52,
            color: AppColors.textDim,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: <TextInputFormatter>[
            if (keyboardType == TextInputType.emailAddress)
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
          style: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 18, color: AppColors.textDim),
            errorText: errorText,
            errorStyle: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.danger,
            ),
          ),
        ),
      ],
    );
  }
}

/// Inline error banner, matching the `⚠️` treatment used by the bottom sheets.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Text(
        '⚠️ $message',
        style: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12.8,
          color: Color(0xFFFCA5A5),
        ),
      ),
    );
  }
}

/// Success banner — used for "check your inbox" style confirmations.
class AuthNoticeBanner extends StatelessWidget {
  const AuthNoticeBanner({
    super.key,
    required this.message,
    this.icon = Icons.check_circle_rounded,
    this.color = AppColors.success,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12.8,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented sign-in / create-account switch.
class AuthModeToggle extends StatelessWidget {
  const AuthModeToggle({
    super.key,
    required this.isRegister,
    required this.onChanged,
  });

  final bool isRegister;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: <Widget>[
          _segment('Sign In', !isRegister, () => onChanged(false)),
          _segment('Register', isRegister, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: selected ? kPrimaryButtonGradient : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13.6,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
