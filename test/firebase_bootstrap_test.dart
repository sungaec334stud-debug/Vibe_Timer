import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_study_timer/services/auth_service.dart';
import 'package:vibe_study_timer/services/firebase_bootstrap.dart';

void main() {
  group('bootstrapFirebase', () {
    // The regression this pins: on a desktop target the generated
    // `currentPlatform` getter throws `UnsupportedError`, which used to be
    // caught by the generic handler and reported as a misconfigured project.
    test('reports an unsupported platform instead of a broken config', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final FirebaseStatus status = await bootstrapFirebase();

      expect(status, isA<FirebaseUnsupportedPlatform>());
      expect((status as FirebaseUnsupportedPlatform).platformLabel,
          'Windows desktop');
      expect(describeFirebaseStatus(status), isNot(contains('flutterfire')));
    });

    test('classifies macOS the same way', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(await bootstrapFirebase(), isA<FirebaseUnsupportedPlatform>());
    });
  });

  group('describeFirebaseStatus', () {
    test('tells you how to link a project when none is linked', () {
      final String message =
          describeFirebaseStatus(const FirebaseNotConfigured());

      expect(message, contains('flutterfire configure'));
      // Must not be the old dead-end string that sent the user hunting.
      expect(message, isNot(contains('not configured for this build')));
    });

    test('names the actual error when a project is misconfigured', () {
      final String message = describeFirebaseStatus(
        FirebaseInitFailed(StateError('API key not valid')),
      );

      expect(message, contains('API key not valid'));
      expect(message, contains('flutterfire configure'));
    });

    test('says nothing when Firebase is healthy', () {
      expect(describeFirebaseStatus(const FirebaseReady()), isEmpty);
    });

    test('the two failure modes do not give the same advice', () {
      expect(
        describeFirebaseStatus(const FirebaseNotConfigured()),
        isNot(describeFirebaseStatus(FirebaseInitFailed('boom'))),
      );
    });
  });

  group('FirebaseUnsupportedPlatform', () {
    test('names the platform instead of blaming the config', () {
      final String message = describeFirebaseStatus(
        const FirebaseUnsupportedPlatform('Windows desktop'),
      );

      expect(message, contains('Windows desktop'));
      // The old behaviour folded desktop into FirebaseInitFailed, whose only
      // advice was "re-run flutterfire configure" — advice that can never work,
      // because the CLI has no desktop target to generate.
      expect(message, isNot(contains('flutterfire configure')));
    });

    test('points at a target Firebase actually supports', () {
      final String message = describeFirebaseStatus(
        const FirebaseUnsupportedPlatform('Windows desktop'),
      );

      expect(message, contains('flutter run -d chrome'));
    });

    test('is distinct from a misconfigured project', () {
      expect(
        describeFirebaseStatus(
          const FirebaseUnsupportedPlatform('Windows desktop'),
        ),
        isNot(
          describeFirebaseStatus(
            const FirebaseInitFailed('DefaultFirebaseOptions have not been '
                'configured for windows'),
          ),
        ),
      );
    });
  });

  group('NoAuthService', () {
    test('carries an actionable default reason', () {
      expect(
        const NoAuthService().reason,
        contains('flutterfire configure'),
      );
    });

    test('always reports signed out and never throws on signOut', () async {
      const NoAuthService service = NoAuthService();
      expect(service.currentUser, isNull);
      await service.signOut();
    });

    test('throws AuthUnavailable, which carries the reason to the UI', () {
      const NoAuthService service = NoAuthService('because reasons');
      expect(
        () => service.signIn(email: 'a@b.com', password: 'x'),
        throwsA(
          isA<AuthUnavailable>().having(
            (AuthUnavailable e) => e.message,
            'message',
            'because reasons',
          ),
        ),
      );
    });
  });

  group('authErrorMessage', () {
    test('maps the codes people actually hit', () {
      String messageFor(String code) => authErrorMessage(
            fb.FirebaseAuthException(code: code),
          );

      expect(messageFor('wrong-password'), 'Incorrect email or password.');
      expect(messageFor('user-not-found'), 'Incorrect email or password.');
      expect(messageFor('invalid-credential'), 'Incorrect email or password.');
      expect(
        messageFor('email-already-in-use'),
        'An account already exists for that email.',
      );
      expect(
        messageFor('weak-password'),
        'Password must be at least 6 characters.',
      );
      expect(
        messageFor('operation-not-allowed'),
        allOf(
          contains('Authentication'),
          contains('Email/Password'),
          // The provisioning step is the one that is easy to miss and is not
          // obvious from the raw error.
          contains('Identity Platform'),
        ),
      );
      expect(
        messageFor('configuration-not-found'),
        allOf(contains('never set up'), contains('Get started')),
      );
      expect(messageFor('api-key-not-valid'), contains('flutterfire configure'));
      expect(messageFor('unauthorized-domain'), contains('Authorized domains'));
      expect(messageFor('too-many-requests'), contains('Too many attempts'));
      expect(messageFor('network-request-failed'), contains('No network'));
    });

    test('falls back to the SDK message for unknown codes', () {
      expect(
        authErrorMessage(
          fb.FirebaseAuthException(code: 'weird', message: 'something odd'),
        ),
        'something odd',
      );
    });

    test('handles a non-Firebase error without crashing', () {
      expect(authErrorMessage(StateError('boom')), contains('went wrong'));
    });
  });
}
