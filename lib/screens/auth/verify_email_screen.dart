import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/feedback.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import 'widgets/auth_scaffold.dart';

/// Blocks access until the user confirms their ALU email address.
///
/// Polls Firebase every few seconds so the app continues automatically once
/// the link is clicked, with a manual button as a fallback.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _resendCooldown = 30;

  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      context
          .read<AuthProvider>()
          .checkVerified(silent: true)
          .catchError((_) => false);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    try {
      await context.read<AuthProvider>().resendVerification();
      if (!mounted) return;
      showSuccess(context, 'Verification email sent again.');
      setState(() => _secondsLeft = _resendCooldown);
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 0) t.cancel();
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _checkNow() async {
    final verified = await context.read<AuthProvider>().checkVerified();
    if (!mounted || verified) return;
    showError(
      context,
      StateError('Not verified yet. Open the link in your inbox first.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    return AuthScaffold(
      title: 'Verify your email',
      subtitle: 'One last step to keep CampusFix for the ALU community only.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread_rounded,
                size: 48,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'We sent a verification link to',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            auth.email ?? '',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Open it on any device, then come back here. This screen will '
            'continue automatically. Check your spam folder if it is missing.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: "I've verified my email",
            icon: Icons.refresh_rounded,
            isLoading: auth.isBusy,
            onPressed: _checkNow,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _secondsLeft > 0 || auth.isBusy ? null : _resend,
            child: Text(
              _secondsLeft > 0
                  ? 'Resend in ${_secondsLeft}s'
                  : 'Resend verification email',
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: auth.signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Use a different account'),
          ),
        ],
      ),
    );
  }
}
