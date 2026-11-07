import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';
import 'widgets/auth_scaffold.dart';

/// Root widget that routes based on authentication state, so session
/// handling lives in one place rather than in every screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final Widget child = switch (auth.status) {
      AuthStatus.unknown => const SplashView(),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.unverified => const VerifyEmailScreen(),
      AuthStatus.authenticated =>
        auth.profile == null
            ? const SplashView(message: 'Loading your profile…')
            : const MainShell(),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(key: ValueKey(child.runtimeType), child: child),
    );
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(),
            const SizedBox(height: 28),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
