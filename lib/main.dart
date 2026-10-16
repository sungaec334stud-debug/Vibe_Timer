import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'controllers/auth_controller.dart';
import 'controllers/stats_controller.dart';
import 'controllers/timer_controller.dart';
import 'data/local_store.dart';
import 'services/audio_service.dart';
import 'services/auth_service.dart';
import 'services/firebase_bootstrap.dart';
import 'services/firestore_backend.dart';
import 'services/sync_service.dart';

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

  // Firebase is optional at runtime. Without generated credentials the app
  // still runs — it just stays in guest mode, which matches the "sign-in is
  // optional" product decision and keeps `flutter run` working on a fresh
  // clone. The failure is classified rather than swallowed so the UI can tell
  // "no project linked" apart from "project is misconfigured".
  final FirebaseStatus firebase = await bootstrapFirebase();
  if (firebase is! FirebaseReady) {
    debugPrint('Firebase disabled, running in guest mode: '
        '${describeFirebaseStatus(firebase)}');
  }

  final String? accountsReason = firebase is FirebaseReady
      ? null
      : describeFirebaseStatus(firebase);

  final AuthService authService = accountsReason == null
      ? FirebaseAuthService()
      : NoAuthService(accountsReason);

  final SyncService syncService = FirestoreSyncService(
    store,
    firebase is FirebaseReady
        ? FirestoreBackend(FirebaseFirestore.instance)
        : null,
  );

  final TimerController timer = TimerController(store, audio, syncService);
  final StatsController stats = StatsController(store, syncService);
  final AuthController auth =
      AuthController(authService, syncService, stats, accountsReason)..start();

  runApp(
    VibeTimerApp(
      store: store,
      audio: audio,
      authService: authService,
      syncService: syncService,
      timer: timer,
      stats: stats,
      auth: auth,
    ),
  );
}
