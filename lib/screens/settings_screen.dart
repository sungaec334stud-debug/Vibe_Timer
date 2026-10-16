import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/stats_controller.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

/// Profile screen reached from the home app bar when signed in.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();
    final StatsController stats = context.watch<StatsController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Account', style: AppTextStyles.heading),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            if (auth.user == null)
              const AuthNoticeBanner(
                message: 'You are browsing as a guest. Sessions and prompts '
                    'are stored on this device only.',
                icon: Icons.person_off_outlined,
                color: AppColors.warning,
              )
            else
              _ProfileCard(
                initials: auth.user!.initials,
                email: auth.user!.email,
              ),

            const SizedBox(height: 22),
            _SyncCard(status: auth.syncStatus),
            const SizedBox(height: 14),
            _StatsCard(
              sessions: stats.stats.totalSessions,
              minutes: stats.stats.totalMinutes,
              prompts: stats.stats.totalPrompts,
            ),
            const SizedBox(height: 26),

            if (auth.isSignedIn)
              GradientButton(
                label: 'Sign Out',
                icon: Icons.logout_rounded,
                isPrimary: false,
                isBusy: auth.isBusy,
                onPressed: () => _confirmSignOut(context),
              )
            else
              GradientButton(
                label: 'Sign In or Register',
                onPressed: () => Navigator.of(context).pop(),
              ),

            if (auth.error != null) ...<Widget>[
              const SizedBox(height: 16),
              AuthErrorBanner(message: auth.error!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Sign out?', style: AppTextStyles.cardTitle),
        content: const Text(
          'Your sessions and prompt log stay safe in the cloud, and this '
          'device will clear its copy when you sign out.',
          style: AppTextStyles.caption,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Sign out',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<AuthController>().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.initials, required this.email});

  final String initials;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: kPrimaryButtonGradient,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: AppFonts.main,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('SIGNED IN', style: AppTextStyles.badge),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;
    late final String label;
    late final String detail;

    switch (status.phase) {
      case SyncPhase.syncing:
        icon = Icons.sync_rounded;
        color = AppColors.accentCyan;
        label = 'SYNCING';
        detail = 'Uploading and downloading your data…';
      case SyncPhase.synced:
        icon = Icons.cloud_done_rounded;
        color = AppColors.success;
        label = 'SYNCED';
        detail = status.lastSyncedAt == null
            ? 'Backed up to the cloud.'
            : 'Last synced ${_format(status.lastSyncedAt!)}';
      case SyncPhase.failed:
        icon = Icons.cloud_off_rounded;
        color = AppColors.warning;
        label = 'OFFLINE';
        detail = status.message ??
            'Changes stay on this device and will sync when you reconnect.';
      case SyncPhase.idle:
        icon = Icons.cloud_off_rounded;
        color = AppColors.textDim;
        label = 'LOCAL ONLY';
        detail = 'Sign in to back up your sessions to the cloud.';
    }

    return _InfoCard(
      icon: icon,
      color: color,
      badge: label,
      body: detail,
      spinner: status.phase == SyncPhase.syncing,
    );
  }

  static String _format(DateTime time) {
    final Duration delta = DateTime.now().difference(time);
    if (delta.inSeconds < 60) return 'just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    return '${delta.inDays}d ago';
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.sessions,
    required this.minutes,
    required this.prompts,
  });

  final int sessions;
  final int minutes;
  final int prompts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _metric('SESSIONS', '$sessions'),
          _metric('MINUTES', '$minutes'),
          _metric('PROMPTS', '$prompts'),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.52,
              color: AppColors.textDim,
            ),
          ),
        ],
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.badge,
    required this.body,
    this.spinner = false,
  });

  final IconData icon;
  final Color color;
  final String badge;
  final String body;
  final bool spinner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          spinner
              ? SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: color,
                  ),
                )
              : Icon(icon, size: 19, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  badge,
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 10.4,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.52,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(body, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
