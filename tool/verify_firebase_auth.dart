// Checks whether the Firebase console is set up well enough for login and
// register to work, without you having to read app error messages and guess.
//
//   dart run tool/verify_firebase_auth.dart
//
// It reads the credentials out of `lib/firebase_options.dart` and asks the
// Identity Toolkit and Firestore REST APIs two read-only questions:
//
//   1. Is Email/Password actually enabled (or has Auth never been initialised)?
//   2. Does the Firestore database exist, and are the security rules deployed?
//
// Read-only: it signs in with a `.invalid` address that can never be
// registered, so no account is created and no email is ever sent. The only
// side effect is the failed-attempt counter, and one request will not move it.

import 'dart:convert';
import 'dart:io';

/// Reserved by RFC 2606 — guaranteed undeliverable and unregistered.
const String _probeEmail = 'auth-probe-does-not-exist@example.invalid';
const String _probePassword = 'not-a-real-password';

Future<void> main(List<String> args) async {
  final File options = File('lib/firebase_options.dart');
  if (!options.existsSync()) {
    _fail('lib/firebase_options.dart is missing. Run `flutterfire configure`.');
  }

  final String source = options.readAsStringSync();
  final String? apiKey = _capture(source, "apiKey: '");
  final String? projectId = _capture(source, "projectId: '");

  if (apiKey == null || projectId == null) {
    _fail('Could not read apiKey/projectId from lib/firebase_options.dart. '
        'It is probably still the unconfigured placeholder — run '
        '`flutterfire configure`.');
  }

  stdout.writeln('Project : $projectId');
  stdout.writeln('API key : ${_mask(apiKey)}');
  stdout.writeln('');

  final String authVerdict = await _checkAuth(apiKey);
  stdout.writeln('1. Email/Password sign-in');
  stdout.writeln('   $authVerdict');
  stdout.writeln('');

  final String firestoreVerdict = await _checkFirestore(apiKey, projectId);
  stdout.writeln('2. Firestore (needed for sync, not for sign-in itself)');
  stdout.writeln('   $firestoreVerdict');
  stdout.writeln('');

  stdout.writeln('Console: https://console.firebase.google.com/project/'
      '$projectId/authentication/providers');
}

// ---------------------------------------------------------------- auth

Future<String> _checkAuth(String apiKey) async {
  final _Response response = await _post(
    'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword'
        '?key=$apiKey',
    <String, dynamic>{
      'email': _probeEmail,
      'password': _probePassword,
      'returnSecureToken': true,
    },
  );

  final String code = _errorCode(response);

  if (code == 'API_KEY_INVALID') {
    return 'BROKEN — the API key is not registered to a Firebase project.\n'
        '      Re-run `flutterfire configure`.';
  }

  if (code == 'CONFIGURATION_NOT_FOUND') {
    return 'BROKEN — Authentication has never been initialised for this '
        'project.\n'
        '      This is the one that bites on a project that was set up by '
        'adding\n'
        '      apps but never opening the Authentication tab. No code change '
        'can\n'
        '      fix it. Open the console → Authentication → "Get started", '
        'then\n'
        '      enable Email/Password.';
  }

  if (code == 'OPERATION_NOT_ALLOWED') {
    return 'BROKEN — the provider exists but Email/Password is not enabled.\n'
        '      Console → Authentication → Sign-in method → enable '
        'Email/Password.';
  }

  if (code == 'EMAIL_NOT_FOUND' ||
      code == 'INVALID_LOGIN_CREDENTIALS' ||
      code == 'INVALID_PASSWORD') {
    return 'OK — Email/Password is enabled and Auth is configured. The probe '
        'account\n'
        '      does not exist, which is exactly what we expect.';
  }

  return 'UNKNOWN (HTTP ${response.status})\n'
      '      ${_trim(response.body)}\n'
      '      Check the console link above.';
}

// ------------------------------------------------------------ firestore

Future<String> _checkFirestore(String apiKey, String projectId) async {
  final _Response response = await _get(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/'
        '(default)/documents/users/__auth_probe__?key=$apiKey',
  );

  final String body = response.body;

  if (body.contains('does not exist') ||
      body.contains('Database') && body.contains('NOT_FOUND')) {
    return 'BROKEN — the database has not been created.\n'
        '      Console → Firestore Database → Create database.';
  }

  if (response.status == 403) {
    return 'OK — the database exists and rules are denying anonymous access, '
        'which is\n'
        '      what the shipped firestore.rules should do '
        '(`firebase deploy --only firestore:rules`).';
  }

  if (body.contains('Requested entity was not found')) {
    return 'Database exists, but reads are still wide open — the security '
        'rules were\n'
        '      never deployed. Run `firebase deploy --only firestore:rules`.';
  }

  return 'UNKNOWN (HTTP ${response.status}) — ${_trim(body)}';
}

// --------------------------------------------------------------- helpers

Future<_Response> _post(String url, Map<String, dynamic> body) async {
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest request = await client.postUrl(Uri.parse(url));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
    final _Response response = await _send(request);
    return response;
  } finally {
    client.close();
  }
}

Future<_Response> _get(String url) async {
  final HttpClient client = HttpClient();
  try {
    final _Response response = await _send(await client.getUrl(Uri.parse(url)));
    return response;
  } finally {
    client.close();
  }
}

Future<_Response> _send(HttpClientRequest request) async {
  final HttpClientResponse response = await request.close();
  return _Response(
    response.statusCode,
    await response.transform(utf8.decoder).join(),
  );
}

/// Pulls the `error.message` out of a Google API JSON error envelope.
String _errorCode(_Response response) {
  if (response.status == 200) return '';
  try {
    final Object? decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final Object? error = decoded['error'];
      if (error is Map<String, dynamic>) {
        return (error['message'] as String?) ?? '';
      }
    }
  } on FormatException {
    // Fall through to the raw body.
  }
  return response.body;
}

String? _capture(String source, String prefix) {
  final int start = source.indexOf(prefix);
  if (start == -1) return null;
  final int from = start + prefix.length;
  final int end = source.indexOf("'", from);
  if (end == -1) return null;
  return source.substring(from, end);
}

String _mask(String key) =>
    key.length <= 8 ? '********' : '${key.substring(0, 6)}…${key.substring(key.length - 4)}';

String _trim(String body) {
  final String flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flat.length <= 160 ? flat : '${flat.substring(0, 157)}...';
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(2);
}

class _Response {
  const _Response(this.status, this.body);

  final int status;
  final String body;
}