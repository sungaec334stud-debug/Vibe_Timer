import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/stats_controller.dart';
import '../controllers/timer_controller.dart';
import '../models/study_models.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/class_rule_card.dart';
import '../widgets/custom_timer_sheet.dart';
import '../widgets/lab_roadmap.dart';
import '../widgets/preset_selector.dart';
import '../widgets/quick_prompt_sheet.dart';
import '../widgets/session_stats_bar.dart';
import '../widgets/timer_controls.dart';
import '../widgets/timer_dial.dart';
import '../widgets/toast_banner.dart';

/// The single screen of the app.
///
/// Flutter port of `App.jsx`. The `MobileFrame` phone-chassis wrapper was
/// dropped: on a real device the OS already provides the status bar and
/// safe areas, so this uses a native `Scaffold` + `AppBar` instead.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _toastMessage;
  bool _soundMuted = false;

  @override
  void initState() {
    super.initState();

    _soundMuted = context.read<AudioService>().isMuted;

    final TimerController timer = context.read<TimerController>();
    timer.onToast = _showToast;
    timer.onSessionComplete = () {
      context.read<StatsController>().refreshAfterSession();
      _showToast('🎉 Session Complete! Awesome vibe focus.');
    };
  }

  void _showToast(String message) {
    if (!mounted) return;
    setState(() => _toastMessage = message);
    Future<void>.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted || _toastMessage != message) return;
      setState(() => _toastMessage = null);
    });
  }

  Future<void> _toggleSound() async {
    final AudioService audio = context.read<AudioService>();
    final bool next = await audio.toggleMute();
    if (!mounted) return;
    setState(() => _soundMuted = next);
    _showToast(next ? 'Sound Muted' : 'Audio Chime Enabled');
  }

  void _handlePresetSelect(String presetId) {
    final TimerController timer = context.read<TimerController>();
    if (presetId == 'custom') {
      CustomTimerSheet.show(
        context,
        onConfirm: (int totalSeconds) {
          timer.selectPreset('custom', customSeconds: totalSeconds.toDouble());
        },
      );
    } else {
      timer.selectPreset(presetId);
    }
  }

  Future<void> _openPromptSheet(String? phaseId) async {
    final StatsController stats = context.read<StatsController>();
    await QuickPromptSheet.show(
      context,
      currentPhaseId: phaseId,
      prompts: stats.prompts,
      onSubmit: ({
        required String phase,
        required String text,
        String? outcome,
      }) async {
        stats.addPrompt(phase: phase, text: text, outcome: outcome);
        _showToast('Prompt logged to session!');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TimerController timer = context.watch<TimerController>();
    final StudyStats stats = context.watch<StatsController>().stats;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 66,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('>_ APPLICATION DEV', style: AppTextStyles.badge),
            ShaderMask(
              shaderCallback: (Rect bounds) => const LinearGradient(
                colors: <Color>[Colors.white, AppColors.accentPurpleLight],
                stops: <double>[0.4, 1],
              ).createShader(bounds),
              child: const Text(
                'Vibe Timer',
                style: TextStyle(
                  fontFamily: AppFonts.main,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          _HeaderAction(
            icon: _soundMuted
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            tooltip: _soundMuted ? 'Unmute sound' : 'Mute sound',
            onPressed: _toggleSound,
          ),
          _HeaderAction(
            icon: Icons.edit_rounded,
            tooltip: 'Quick log prompt / error',
            onPressed: () => _openPromptSheet(timer.currentPhase?.id),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            if (_toastMessage != null) ...<Widget>[
              ToastBanner(message: _toastMessage!),
              const SizedBox(height: 12),
            ],
            PresetSelector(
              currentPresetId: timer.preset.id,
              onSelectPreset: _handlePresetSelect,
            ),
            const SizedBox(height: 20),
            Center(
              child: TimerDial(
                timeFormatted: timer.timeFormatted,
                progressFraction: timer.progressFraction,
                isRunning: timer.isRunning,
                presetId: timer.preset.id,
                phase: timer.currentPhase,
              ),
            ),
            const SizedBox(height: 8),
            TimerControls(
              isRunning: timer.isRunning,
              onToggle: timer.toggle,
              onReset: timer.reset,
              onSkipPhase: timer.skipPhase,
              showSkipPhase: timer.isLabActive,
            ),
            const SizedBox(height: 20),
            LabRoadmap(
              currentPhaseIndex: timer.phaseIndex,
              isLabActive: timer.isLabActive,
            ),
            const SizedBox(height: 20),
            const ClassRuleCard(),
            const SizedBox(height: 20),
            SessionStatsBar(stats: stats),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: 0.05),
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.borderSubtle),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, size: 18, color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}