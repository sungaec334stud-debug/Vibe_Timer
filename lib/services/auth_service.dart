import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/auth_user.dart';

/// Authentication surface used by [AuthController].
///
/// Everything above this line talks to [AuthUser] and plain strings, which
/// keeps `firebase_auth` out of the widget tree and makes the controller
/// testable with [NoAuthService].
abstract class AuthService {
  /// Emits on sign-in, sign-out and on cold start (where it replays the
  /// persisted session, because Firebase Auth persists by default on Android,
  /// iOS and web).
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  Future<AuthUser> signIn({required String email, required String password});

  Future<AuthUser> register({required String email, required String password});

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);
}

/// Raised when an auth method is called on a build with no Firebase project.
class AuthUnavailable implements Exception {
  const AuthUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

/// [AuthService] over the real Firebase Auth SDK.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService([fb.FirebaseAuth? auth])
      : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().map(_map);

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final fb.UserCredential credential = await _auth
        .signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
    return _require(credential.user);
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    final fb.UserCredential credential = await _auth
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
    return _require(credential.user);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  static AuthUser? _map(fb.User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  /// Guards the SDK's nullable `User`, which should never actually be null
  /// after a successful credential but would otherwise crash the UI on a NPE.
  static AuthUser _require(fb.User? user) {
    final AuthUser? mapped = _map(user);
    if (mapped == null) {
      throw fb.FirebaseAuthException(
        code: 'internal-error',
        message: 'Sign-in succeeded but returned no user.',
      );
    }
    return mapped;
  }
}

/// Stand-in used when Firebase is not configured or failed to start.
///
/// The app deliberately degrades to guest-only rather than crashing at
/// startup, which matches the "login is optional" product decision.
class NoAuthService implements AuthService {
  const NoAuthService([
    this.reason =
        'Accounts are not set up in this build. Run `flutterfire configure` '
            'to link a Firebase project, then restart the app.',
  ]);

  final String reason;

  @override
  Stream<AuthUser?> authStateChanges() => const Stream<AuthUser?>.empty();

  @override
  AuthUser? get currentUser => null;

  Never _fail() => throw AuthUnavailable(reason);

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async => _fail();

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async => _fail();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async => _fail();
}

/// Turns a raw SDK failure into something worth showing a person.
String authErrorMessage(Object error) {
  if (error is AuthUnavailable) return error.message;

  if (error is fb.FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is switched off for this Firebase '
            'project. In the console go to Authentication → Sign-in method and '
            'enable Email/Password. The first time you open that page Firebase '
            'asks you to initialise Identity Platform — accept it, or sign-in '
            'keeps failing with "configuration not found".';
      case 'configuration-not-found':
        return 'Firebase Authentication was never set up for this project. In '
            'the console open Authentication and click "Get started" to '
            'initialise it, then enable the Email/Password provider.';
      case 'api-key-not-valid':
      case 'invalid-api-key':
        return 'The Firebase API key in this build is not valid. Re-run '
            '`flutterfire configure`.';
      case 'project-not-found':
        return 'This build points at a Firebase project that no longer '
            'exists. Re-run `flutterfire configure`.';
      case 'unauthorized-domain':
        return 'This site is not an authorised domain. Add its host under '
            'Authentication → Settings → Authorized domains.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a moment.';
      case 'network-request-failed':
        return 'No network connection. Check your connection and retry.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  return 'Something went wrong. Please try again.';
}
