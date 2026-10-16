import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'controllers/auth_controller.dart';
import 'controllers/stats_controller.dart';
import 'controllers/timer_controller.dart';
import 'data/local_store.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';

/// Wires up the long-lived services and renders [HomeScreen].
///
/// The three controllers are constructed in `main.dart` and injected here
/// rather than created inline, because [AuthController] needs a
/// [StatsController] to repaint after a sync merge. That also keeps the whole
/// object graph mockable — tests never touch Firebase.
class VibeTimerApp extends StatelessWidget {
  const VibeTimerApp({
    super.key,
    required this.store,
    required this.audio,
    required this.authService,
    required this.syncService,
    required this.timer,
    required this.stats,
    required this.auth,
  });

  final LocalStore store;
  final AudioService audio;
  final AuthService authService;
  final SyncService syncService;
  final TimerController timer;
  final StatsController stats;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        Provider<LocalStore>.value(value: store),
        Provider<AudioService>.value(value: audio),
        Provider<AuthService>.value(value: authService),
        Provider<SyncService>.value(value: syncService),
        ChangeNotifierProvider<TimerController>.value(value: timer),
        ChangeNotifierProvider<StatsController>.value(value: stats),
        ChangeNotifierProvider<AuthController>.value(value: auth),
      ],
      child: MaterialApp(
        title: 'Vibe Study Timer',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // Login is optional, so there is no auth gate here — the timer is
        // usable immediately and as a guest forever.
        home: const HomeScreen(),
      ),
    );
  }
}
