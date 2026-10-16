import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

/// Sign-in / registration. Presented as a route from the home app bar.
///
/// Single screen with a segmented toggle rather than two, which keeps the
/// form state (and the autofill hints) in one place.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  /// Pushes the screen. Resolves to true if a session was established.
  static Future<bool?> show(BuildContext context) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AuthScreen()),
    );
  }

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _isRegister = false;
  bool _obscure = true;
  String? _fieldError;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _setFieldError(String? message) {
    if (_fieldError == message) return;
    setState(() => _fieldError = message);
  }

  Future<void> _submit() async {
    final AuthController auth = context.read<AuthController>();
    // The button is already disabled, but keyboard "done"/submit on a field
    // bypasses it — fail closed here too.
    if (!auth.accountsAvailable) return;

    final String? emailError = validateEmail(_email.text);
    if (emailError != null) {
      _setFieldError(emailError);
      return;
    }
    final String? passwordError =
        validatePassword(_password.text, isRegister: _isRegister);
    if (passwordError != null) {
      _setFieldError(passwordError);
      return;
    }
    if (_isRegister) {
      final String? confirmError =
          validatePasswordConfirmation(_confirm.text, _password.text);
      if (confirmError != null) {
        _setFieldError(confirmError);
        return;
      }
    }

    _setFieldError(null);
    auth.clearError();
    setState(() => _notice = null);

    final bool ok = _isRegister
        ? await auth.register(email: _email.text, password: _password.text)
        : await auth.signIn(email: _email.text, password: _password.text);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {});
  }

  Future<void> _sendReset() async {
    final AuthController auth = context.read<AuthController>();
    if (!auth.accountsAvailable) return;

    final String? emailError = validateEmail(_email.text);
    if (emailError != null) {
      _setFieldError(emailError);
      return;
    }

    _setFieldError(null);
    final bool ok = await auth.sendPasswordResetEmail(_email.text);
    if (!mounted) return;
    setState(() {
      _notice = ok
          ? 'Password reset sent. Check ${_email.text.trim()} for the link.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text('Account', style: AppTextStyles.heading),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            32 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ShaderMask(
                shaderCallback: (Rect bounds) => kPurpleCyanGradient
                    .createShader(bounds),
                child: const Text(
                  'Sync your focus',
                  style: TextStyle(
                    fontFamily: AppFonts.main,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to back up your sessions and prompt log to the '
                'cloud. Or keep working as a guest — everything stays on '
                'this device either way.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 26),

              // Shown before the user types anything, so a build without
              // Firebase never looks like it rejected their password.
              if (!auth.accountsAvailable) ...<Widget>[
                AuthNoticeBanner(
                  message: auth.accountsUnavailableReason!,
                  icon: Icons.cloud_off_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 18),
              ],

              AuthModeToggle(
                isRegister: _isRegister,
                onChanged: (bool value) {
                  setState(() {
                    _isRegister = value;
                    _fieldError = null;
                    _notice = null;
                  });
                  context.read<AuthController>().clearError();
                },
              ),
              const SizedBox(height: 22),

              AuthTextField(
                label: 'EMAIL',
                controller: _email,
                hint: 'you@example.com',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofocus: true,
                enabled: !auth.isBusy,
                errorText: _fieldError,
              ),
              const SizedBox(height: 16),

              AuthTextField(
                label: 'PASSWORD',
                controller: _password,
                hint: _isRegister ? 'At least 6 characters' : '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                textInputAction:
                    _isRegister ? TextInputAction.next : TextInputAction.done,
                enabled: !auth.isBusy,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: auth.isBusy
                      ? null
                      : () => setState(() => _obscure = !_obscure),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      _obscure ? 'Show' : 'Hide',
                      style: const TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 10.9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPurpleLight,
                      ),
                    ),
                  ),
                ),
              ),

              if (_isRegister) ...<Widget>[
                const SizedBox(height: 10),
                AuthTextField(
                  label: 'CONFIRM PASSWORD',
                  controller: _confirm,
                  hint: 'Re-enter password',
                  icon: Icons.lock_reset_rounded,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  enabled: !auth.isBusy,
                  onSubmitted: (_) => _submit(),
                ),
              ],

              if (_notice != null) ...<Widget>[
                const SizedBox(height: 18),
                AuthNoticeBanner(message: _notice!),
              ],

              if (auth.error != null) ...<Widget>[
                const SizedBox(height: 18),
                AuthErrorBanner(message: auth.error!),
              ],

              const SizedBox(height: 22),
              GradientButton(
                label: _isRegister ? 'Create Account' : 'Sign In',
                isBusy: auth.isBusy,
                // Disabled up front when there is no auth provider at all —
                // submitting could only ever produce the same banner again.
                onPressed: auth.accountsAvailable ? _submit : null,
              ),
              const SizedBox(height: 12),

              if (!_isRegister)
                Center(
                  child: TextButton(
                    onPressed:
                        auth.accountsAvailable && !auth.isBusy ? _sendReset : null,
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13.6,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: auth.isBusy
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(
                    // When accounts are dead the guest path is the only path,
                    // so make it the obvious one.
                    auth.accountsAvailable
                        ? 'Continue as guest'
                        : 'Go back to the timer',
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13.6,
                      color: AppColors.textDim,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
