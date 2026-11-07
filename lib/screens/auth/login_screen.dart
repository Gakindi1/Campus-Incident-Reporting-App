import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/feedback.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import 'register_screen.dart';
import 'widgets/auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    try {
      await context.read<AuthProvider>().signIn(
        _emailController.text,
        _passwordController.text,
      );
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _forgotPassword() async {
    final emailError = Validators.email(_emailController.text);
    if (emailError != null) {
      showError(context, StateError('Enter your ALU email above first.'));
      return;
    }
    try {
      await context.read<AuthProvider>().sendPasswordReset(
        _emailController.text,
      );
      if (mounted) {
        showSuccess(context, 'Password reset link sent to your inbox.');
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<AuthProvider, bool>((a) => a.isBusy);
    return AuthScaffold(
      title: 'Welcome back',
      subtitle:
          'Sign in with your ALU account to report and track campus issues.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledField(
              label: 'ALU email',
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                decoration: const InputDecoration(
                  hintText: 'name@alustudent.com',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
            ),
            const SizedBox(height: 18),
            LabeledField(
              label: 'Password',
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: Validators.loginPassword,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Your password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isBusy ? null : _forgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Sign in',
              icon: Icons.login_rounded,
              isLoading: isBusy,
              onPressed: _submit,
            ),
            const Spacer(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'New to CampusFix?',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('Create account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
