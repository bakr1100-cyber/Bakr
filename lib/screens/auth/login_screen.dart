import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/big_button.dart';
import '../../widgets/responsive_body.dart';

/// Combined login/register screen - a single toggle between the two modes
/// instead of two separate screens, since they share every field.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final language = AppLocalizations.of(context).language;
    final error = _isRegisterMode
        ? await auth.register(email: email, password: password, language: language)
        : await auth.signIn(email: email, password: password, language: language);

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _errorMessage = error;
    });
    if (error == null) Navigator.of(context).pop();
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
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(labelText: t('password')),
              ),
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
