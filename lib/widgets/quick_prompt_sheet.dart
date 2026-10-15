import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/study_models.dart';
import '../theme/app_theme.dart';

/// Slide-up prompt / error traceback logger.
/// Port of `QuickPromptSheet.jsx` (rendered as a Flutter bottom sheet).
class QuickPromptSheet extends StatefulWidget {
  const QuickPromptSheet({
    super.key,
    required this.currentPhaseId,
    required this.prompts,
    required this.onSubmit,
  });

  /// Pre-selects the phase dropdown, e.g. `build`.
  final String? currentPhaseId;
  final List<PromptLog> prompts;
  final Future<void> Function({
    required String phase,
    required String text,
    String? outcome,
  }) onSubmit;

  /// Shows the sheet and returns once dismissed.
  static Future<void> show(
    BuildContext context, {
    required String? currentPhaseId,
    required List<PromptLog> prompts,
    required Future<void> Function({
      required String phase,
      required String text,
      String? outcome,
    }) onSubmit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext _) => QuickPromptSheet(
        currentPhaseId: currentPhaseId,
        prompts: prompts,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<QuickPromptSheet> createState() => _QuickPromptSheetState();
}

class _QuickPromptSheetState extends State<QuickPromptSheet> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _outcomeController = TextEditingController();
  String _phase = 'build';

  @override
  void initState() {
    super.initState();
    _phase = widget.currentPhaseId ?? 'build';
  }

  @override
  void dispose() {
    _textController.dispose();
    _outcomeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String text = _textController.text.trim();
    if (text.isEmpty) {
      _showError('Please enter prompt text first');
      return;
    }
    await widget.onSubmit(
      phase: _phase,
      text: text,
      outcome: _outcomeController.text.trim(),
    );
    if (!mounted) return;
    _textController.clear();
    _outcomeController.clear();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.bgSheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.borderActive),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                '✍️ Quick Prompt & Error Log',
                style: TextStyle(
                  fontFamily: AppFonts.main,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
          const SizedBox(height: 4),
          const Text(
            'Record prompts or paste error tracebacks to feed back to AI '
            '(Slide 9 Demo pattern).',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: _phase,
                    dropdownColor: AppColors.bgCardElevated,
                    decoration: const InputDecoration(),
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13.6,
                      color: Colors.white,
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'plan',
                        child: Text('Phase 1: Plan'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'build',
                        child: Text('Phase 2: Build (Code / Error)'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'audit',
                        child: Text('Phase 3: Audit (Security)'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'reflect',
                        child: Text('Phase 4: Reflect'),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) setState(() => _phase = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _textController,
                    maxLines: 4,
                    minLines: 3,
                    style: const TextStyle(
                      fontFamily: AppFonts.mono,
                      fontSize: 12.8,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter the prompt or paste error traceback '
                          'here...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _outcomeController,
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13.6,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Outcome (e.g. AI fixed 500 error / created '
                          'database)',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SubmitButton(onPressed: _submit),
                  if (widget.prompts.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 18),
                    Text(
                      'Logged This Session (${widget.prompts.length}):',
                      style: AppTextStyles.monoSmall.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    for (int i = 0; i < widget.prompts.length; i++)
                      _PromptTile(prompt: widget.prompts[i], index: i),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: kPrimaryButtonGradient,
        borderRadius: BorderRadius.circular(AppRadii.full),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.accentPurpleGlow,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.full),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Center(
              child: Text(
                '+ Record Prompt Iteration',
                style: TextStyle(
                  fontFamily: AppFonts.main,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptTile extends StatelessWidget {
  const _PromptTile({required this.prompt, required this.index});

  final PromptLog prompt;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '#${index + 1} [${prompt.phase.toUpperCase()}]',
                style: const TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentCyan,
                ),
              ),
              Text(
                DateFormat.jm().format(prompt.timestamp),
                style: const TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 10.4,
                  color: AppColors.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            prompt.text,
            style: const TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 12,
              color: Color(0xFFE2E8F0),
            ),
          ),
          if (prompt.outcome != null && prompt.outcome!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              '↳ ${prompt.outcome}',
              style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }
}