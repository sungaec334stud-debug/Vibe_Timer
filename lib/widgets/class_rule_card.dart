import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The Slide 14 class rule banner. Port of `ClassRuleCard.jsx`.
class ClassRuleCard extends StatelessWidget {
  const ClassRuleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0x338B5CF6),
            Color(0x2606B6D4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderActive),
      ),
      child: Column(
        children: <Widget>[
          const Text(
            'The Rule For This Class (Slide 14)',
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 10.4,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.65,
              color: AppColors.accentCyan,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '"You may vibe code. You may not submit code you can\'t explain."',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.main,
              fontSize: 15.2,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Low stakes: let vibes flow • High stakes: engineer it properly',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}