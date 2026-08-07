import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/big_button.dart';
import '../../widgets/responsive_body.dart';

/// Combined login/register screen - a single toggle between the two modes
/// instead of two separate screens, since they share every field.
///
/// Registration flow (standard double opt-in, per explicit request):
/// register -> password must be re-typed and match -> account created ->
/// verification email sent -> screen switches to login mode with a
/// confirmation message -> user must click the emailed link before
/// [AuthProvider.signIn] will let them in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context).t;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode && password != _confirmPasswordController.text) {
      setState(() => _errorMessage = t('authErrorPasswordMismatch'));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final language = AppLocalizations.of(context).language;
    final result = _isRegisterMode
        ? await auth.register(email: email, password: password, language: language)
        : await auth.signIn(email: email, password: password, language: language);

    if (!mounted) return;
    switch (result) {
      case AuthSuccess():
        Navigator.of(context).pop();
      case AuthNeedsVerification():
        _passwordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _isSubmitting = false;
          _isRegisterMode = false;
          _infoMessage = t('registrationNeedsVerificationBody');
        });
      case AuthFailure(:final message):
        setState(() {
          _isSubmitting = false;
          _errorMessage = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t(_isRegisterMode ? 'register' : 'login'))),
      body: ResponsiveBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_infoMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('registrationNeedsVerificationTitle'),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _infoMessage!,
                        style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(labelText: t('email')),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passwordController,
                obscureText: true,
                autocorrect: false,
                onSubmitted: _isRegisterMode ? null : (_) => _submit(),
                decoration: InputDecoration(labelText: t('password')),
              ),
              if (_isRegisterMode) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  autocorrect: false,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(labelText: t('confirmPassword')),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : BigButton(
                      label: t(_isRegisterMode ? 'register' : 'login'),
                      onPressed: _submit,
                    ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() {
                            _isRegisterMode = !_isRegisterMode;
                            _errorMessage = null;
                            _infoMessage = null;
                          }),
                  child: Text(t(_isRegisterMode ? 'alreadyHaveAccount' : 'dontHaveAccountYet')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
