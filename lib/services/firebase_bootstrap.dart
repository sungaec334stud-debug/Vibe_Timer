import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Why Firebase is or isn't available in this build.
///
/// The distinction matters: "you never configured a project" and "your
/// project is misconfigured" need completely different fixes, and collapsing
/// both into a bool (as this originally did) meant the UI could only ever say
/// something useless.
sealed class FirebaseStatus {
  const FirebaseStatus();
}

/// Initialised successfully — accounts and sync are live.
class FirebaseReady extends FirebaseStatus {
  const FirebaseReady();
}

/// `lib/firebase_options.dart` is still the placeholder, so no project has
/// been linked. This is the default state of a fresh clone.
class FirebaseNotConfigured extends FirebaseStatus {
  const FirebaseNotConfigured();
}

/// A project *is* linked but `Firebase.initializeApp()` rejected it — usually
/// a malformed `firebase_options.dart`, or the platform file
/// (`google-services.json` / `GoogleService-Info.plist`) missing or stale.
///
/// Note this is never a transient network failure: `initializeApp` does not
/// perform I/O, so a throw here means the config itself is wrong.
class FirebaseInitFailed extends FirebaseStatus {
  const FirebaseInitFailed(this.error);

  final Object error;
}

/// This build is running on a platform Firebase ships no SDK for — Windows,
/// macOS or Linux desktop.
///
/// It is deliberately kept separate from [FirebaseInitFailed], which it used to
/// be folded into. `flutterfire configure` has no desktop target to generate,
/// so "re-run flutterfire configure" is advice that can never succeed here;
/// saying it sent people round in circles. The fix is to run the app somewhere
/// Firebase exists, which is what this message says instead.
class FirebaseUnsupportedPlatform extends FirebaseStatus {
  const FirebaseUnsupportedPlatform(this.platformLabel);

  /// Human-readable, e.g. `Windows desktop`.
  final String platformLabel;
}

/// Initialises Firebase, classifying any failure instead of swallowing it.
Future<FirebaseStatus> bootstrapFirebase() async {
  final FirebaseOptions options;
  try {
    options = DefaultFirebaseOptions.currentPlatform;
  } on UnimplementedError {
    // The placeholder is still in place.
    return const FirebaseNotConfigured();
  } on UnsupportedError {
    // The generated `currentPlatform` getter only knows Android, iOS and web,
    // and throws `UnsupportedError` — not `UnimplementedError` — for desktop.
    // Catching it here keeps the "misconfigured project" verdict meaning what
    // it says.
    return FirebaseUnsupportedPlatform(_currentPlatformLabel());
  } catch (error) {
    // The CLI generated a file that throws something else — treat it as a
    // broken config, not a missing one.
    return FirebaseInitFailed(error);
  }

  try {
    await Firebase.initializeApp(options: options);
    return const FirebaseReady();
  } catch (error) {
    return FirebaseInitFailed(error);
  }
}

/// Only reachable from the [FirebaseUnsupportedPlatform] branch, which web
/// cannot hit — `currentPlatform` returns the web options before it ever
/// reaches a platform switch.
String _currentPlatformLabel() => switch (defaultTargetPlatform) {
      TargetPlatform.windows => 'Windows desktop',
      TargetPlatform.macOS => 'macOS desktop',
      TargetPlatform.linux => 'Linux desktop',
      TargetPlatform.fuchsia => 'Fuchsia',
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
    };

/// A short, actionable explanation suitable for showing in the UI.
String describeFirebaseStatus(FirebaseStatus status) {
  return switch (status) {
    FirebaseNotConfigured() =>
      'Accounts are not set up in this build. Run `flutterfire configure` to '
          'link a Firebase project, then restart the app.',
    FirebaseInitFailed(:final error) =>
      'Firebase could not start: $error. Re-run `flutterfire configure` and '
          'make sure the platform config files are in place.',
    FirebaseUnsupportedPlatform(:final platformLabel) =>
      'Firebase has no $platformLabel build, so accounts cannot work here. '
          'Run the app with `flutter run -d chrome`, or on an Android/iOS '
          'device. The timer works fine on this platform as a guest.',
    FirebaseReady() => '',
  };
}
