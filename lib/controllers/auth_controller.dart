import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'stats_controller.dart';

enum AuthStatus {
  /// Firebase has not reported yet — show a splash, not the login screen.
  unknown,
  signedOut,
  signedIn,
}

/// Owns the session lifecycle and drives [SyncService] on every transition.
///
/// Sign-in is optional by design: nothing here gates the timer. The app boots
/// straight into [HomeScreen] and the user can work entirely as a guest.
class AuthController extends ChangeNotifier {
  AuthController(
    this._auth,
    this._sync,
    this._stats, [
    this.accountsUnavailableReason,
  ]);

  final AuthService _auth;
  final SyncService _sync;
  final StatsController _stats;

  /// Non-null when this build has no usable auth provider. The value is a
  /// ready-to-display explanation naming the fix, so the UI can say what to do
  /// instead of failing after the user has already typed their password.
  final String? accountsUnavailableReason;

  /// False when signing in cannot possibly succeed, whatever the credentials.
  bool get accountsAvailable => accountsUnavailableReason == null;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  bool _busy = false;
  String? _error;

  StreamSubscription<AuthUser?>? _authSub;
  StreamSubscription<SyncStatus>? _syncSub;
  bool _disposed = false;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  bool get isSignedIn => _status == AuthStatus.signedIn && _user != null;
  bool get isBusy => _busy;
  String? get error => _error;

  /// Live sync indicator for the settings screen.
  SyncStatus get syncStatus => _sync.status;

  /// Begins listening. Safe to call once; idempotent.
  void start() {
    if (_authSub != null) return;

    _authSub = _auth.authStateChanges().listen(_handleAuthState);

    _syncSub = _sync.statusChanges.listen((SyncStatus _) {
      if (!_disposed) notifyListeners();
    });

    // The stream is async, but [FirebaseAuthService.currentUser] is populated
    // synchronously once the SDK restores a persisted session on cold start.
    final AuthUser? restored = _auth.currentUser;
    if (restored != null) _handleAuthState(restored);
  }

  Future<void> _handleAuthState(AuthUser? user) async {
    final String? previousUid = _user?.uid;
    _user = user;
    _status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    _error = null;
    _safeNotify();

    if (user != null) {
      // Replayed identical user (resume / token refresh) — nothing to redo.
      if (previousUid != user.uid) {
        await _sync.onUserSignedIn(user.uid);
      }
    } else if (previousUid != null) {
      await _sync.onUserSignedOut();
      // The local rows were just wiped; repaint the now-empty stats.
      _stats.refresh();
    }

    _safeNotify();
  }

  // -------------------------------------------------------------- actions

  /// Returns true on success; on failure returns false and sets [error].
  Future<bool> signIn({required String email, required String password}) {
    return _run(() => _auth.signIn(email: email, password: password));
  }

  Future<bool> register({required String email, required String password}) {
    return _run(() => _auth.register(email: email, password: password));
  }

  Future<bool> _run(Future<AuthUser> Function() action) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    _safeNotify();

    try {
      await action();
      return true;
    } catch (error) {
      _error = authErrorMessage(error);
      return false;
    } finally {
      _busy = false;
      _safeNotify();
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    _safeNotify();
    try {
      await _auth.sendPasswordResetEmail(email);
      return true;
    } catch (error) {
      _error = authErrorMessage(error);
      return false;
    } finally {
      _busy = false;
      _safeNotify();
    }
  }

  Future<void> signOut() async {
    if (_busy) return;
    _busy = true;
    _error = null;
    _safeNotify();
    try {
      await _auth.signOut();
    } catch (error) {
      _error = authErrorMessage(error);
    } finally {
      _busy = false;
      _safeNotify();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSub?.cancel();
    _syncSub?.cancel();
    super.dispose();
  }
}

// ------------------------------------------------------------- validation

/// Deliberately loose — Firebase is the real authority on deliverability, and
/// a stricter regex here only rejects valid-but-unusual addresses.
final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  final String email = (value ?? '').trim();
  if (email.isEmpty) return 'Email is required.';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
  return null;
}

String? validatePassword(String? value, {required bool isRegister}) {
  final String password = value ?? '';
  if (password.isEmpty) return 'Password is required.';
  if (isRegister && password.length < 6) {
    return 'Use at least 6 characters.';
  }
  return null;
}

String? validatePasswordConfirmation(
  String? value,
  String password,
) {
  if ((value ?? '').isEmpty) return 'Confirm your password.';
  if (value != password) return 'Passwords do not match.';
  return null;
}
