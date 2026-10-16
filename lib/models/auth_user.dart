/// A signed-in account, decoupled from `firebase_auth`'s `User` so that the
/// widgets and controllers never import the Firebase SDK directly.
class AuthUser {
  const AuthUser({required this.uid, required this.email, this.displayName});

  final String uid;
  final String email;
  final String? displayName;

  /// Up to two letters for the avatar chip — e.g. `ada@example.com` -> `AD`.
  String get initials {
    final String source = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : email.split('@').first;
    if (source.isEmpty) return '?';
    final List<String> parts = source.split(RegExp(r'[\s._-]+'))
      ..removeWhere((String p) => p.isEmpty);
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  String toString() => 'AuthUser($uid, $email)';
}
