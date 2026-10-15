import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/local_store.dart';
import 'services/audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // Opens (and on first launch, seeds) the on-device store that replaced the
  // Node backend.
  final LocalStore store = await LocalStore.open();

  final AudioService audio = AudioService()
    ..restoreMuteState(store.isMuted);

  runApp(VibeTimerApp(store: store, audio: audio));
}