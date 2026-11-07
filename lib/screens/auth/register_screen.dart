import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/feedback.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import 'widgets/auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    try {
      await context.read<AuthProvider>().register(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      // The AuthGate now shows the verification screen underneath; pop the
      // registration route to reveal it.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<AuthProvider, bool>((a) => a.isBusy);
    return AuthScaffold(
      showBack: true,
      title: 'Create your account',
      subtitle: 'Only verified ALU email addresses can join CampusFix.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledField(
              label: 'Full name',
              child: TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: Validators.fullName,
                decoration: const InputDecoration(
                  hintText: 'e.g. Amina Hassan',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            LabeledField(
              label: 'Password',
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
                decoration: InputDecoration(
                  hintText: 'At least 8 characters, letters & numbers',
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
            const SizedBox(height: 16),
            LabeledField(
              label: 'Confirm password',
              child: TextFormField(
                controller: _confirmController,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                validator: Validators.confirmPassword(
                  () => _passwordController.text,
                ),
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'Re-enter your password',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined,
                      color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'We will email you a verification link. You can start '
                      'reporting once your ALU email is confirmed.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Create account',
              icon: Icons.person_add_alt_1_rounded,
              isLoading: isBusy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
