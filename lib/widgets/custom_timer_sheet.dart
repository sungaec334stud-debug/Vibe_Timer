import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Minutes + seconds custom duration picker.
/// Port of `CustomTimerModal.jsx`, including its validation rules.
class CustomTimerSheet extends StatefulWidget {
  const CustomTimerSheet({super.key, required this.onConfirm});

  /// Receives the validated duration in **seconds**.
  final ValueChanged<int> onConfirm;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<int> onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (BuildContext _) => CustomTimerSheet(onConfirm: onConfirm),
    );
  }

  @override
  State<CustomTimerSheet> createState() => _CustomTimerSheetState();
}

class _CustomTimerSheetState extends State<CustomTimerSheet> {
  static const List<({String label, int m, int s})> _quickChips =
      <({String label, int m, int s})>[
    (label: '5m', m: 5, s: 0),
    (label: '10m', m: 10, s: 0),
    (label: '15m', m: 15, s: 0),
    (label: '30m', m: 30, s: 0),
    (label: '45m', m: 45, s: 0),
    (label: '90m', m: 90, s: 0),
  ];

  final TextEditingController _minutesController =
      TextEditingController(text: '25');
  final TextEditingController _secondsController =
      TextEditingController(text: '0');
  String _error = '';

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  int get _minutes => int.tryParse(_minutesController.text.trim()) ?? 0;
  int get _seconds => int.tryParse(_secondsController.text.trim()) ?? 0;
  int get _total => _minutes * 60 + _seconds;

  void _confirm() {
    final String rawMinutes = _minutesController.text.trim();
    final String rawSeconds = _secondsController.text.trim();

    if (rawMinutes.isEmpty || (_minutes < 0)) {
      setState(() => _error = 'Please enter a valid number of minutes '
          '(0 or more).');
      return;
    }
    if (rawSeconds.isEmpty || _seconds < 0 || _seconds > 59) {
      setState(() => _error = 'Seconds must be between 0 and 59.');
      return;
    }
    if (_total < 5) {
      setState(() => _error = 'Total duration must be at least 5 seconds.');
      return;
    }
    if (_total > 8 * 3600) {
      setState(() => _error = 'Maximum duration is 8 hours.');
      return;
    }

    widget.onConfirm(_total);
    Navigator.of(context).pop();
  }

  void _applyChip(int m, int s) {
    setState(() {
      _minutesController.text = '$m';
      _secondsController.text = '$s';
      _error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1A1135), Color(0xFF0E0922)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.borderActive),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Text('⏱️', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Custom Timer',
                        style: TextStyle(
                          fontFamily: AppFonts.main,
                          fontSize: 19.2,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Set your own study duration',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _NumberField(
                    label: 'Minutes',
                    controller: _minutesController,
                    hint: '25',
                    subLabel: '0 – 480',
                    maxLength: 3,
                    onChanged: (_) => setState(() => _error = ''),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 34),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontFamily: AppFonts.mono,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentPurpleLight,
                    ),
                  ),
                ),
                Expanded(
                  child: _NumberField(
                    label: 'Seconds',
                    controller: _secondsController,
                    hint: '0',
                    subLabel: '0 – 59',
                    maxLength: 2,
                    onChanged: (_) => setState(() => _error = ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                for (final ({String label, int m, int s}) chip in _quickChips)
                  _QuickChip(
                    label: chip.label,
                    onTap: () => _applyChip(chip.m, chip.s),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.accentCyan.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                _total > 0
                    ? '⏱ ${_total ~/ 60} min ${_total % 60} s total'
                    : 'Enter a duration above',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 13.6,
                  color: AppColors.accentCyan,
                ),
              ),
            ),
            if (_error.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '⚠️ $_error',
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12.8,
                    color: Color(0xFFFCA5A5),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: _ActionButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _ActionButton(
                    label: 'Set Timer',
                    isPrimary: true,
                    onPressed: _confirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.subLabel,
    required this.maxLength,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String subLabel;
  final int maxLength;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.accentPurpleLight,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(maxLength),
          ],
          style: const TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textDim,
            ),
            filled: true,
            fillColor: const Color(0xE60A0716),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.accentPurple.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.accentPurple.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentPurple, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subLabel,
          style: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 10.4,
            color: AppColors.textDim,
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accentPurple.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.full),
          border: Border.all(
            color: AppColors.accentPurple.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12.8,
            fontWeight: FontWeight.w600,
            color: AppColors.accentPurpleLight,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isPrimary ? null : Colors.white.withValues(alpha: 0.05),
        gradient: isPrimary ? kPrimaryButtonGradient : null,
        borderRadius: BorderRadius.circular(14),
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
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 15.2,
                  fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                  color: isPrimary ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}