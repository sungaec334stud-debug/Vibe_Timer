import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'controllers/stats_controller.dart';
import 'controllers/timer_controller.dart';
import 'data/local_store.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'theme/app_theme.dart';

/// Wires up the three long-lived services and renders [HomeScreen].
class VibeTimerApp extends StatelessWidget {
  const VibeTimerApp({
    super.key,
    required this.store,
    required this.audio,
  });

  final LocalStore store;
  final AudioService audio;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        Provider<LocalStore>.value(value: store),
        Provider<AudioService>.value(value: audio),
        ChangeNotifierProvider<TimerController>(
          create: (_) => TimerController(store, audio),
        ),
        ChangeNotifierProvider<StatsController>(
          create: (_) => StatsController(store),
        ),
      ],
      child: MaterialApp(
        title: 'Vibe Study Timer',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}