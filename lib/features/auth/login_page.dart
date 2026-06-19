import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:bhitte_patro/core/providers/auth_provider.dart';
import 'package:bhitte_patro/core/router/route_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset(
                'assets/logo.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 32),
              Text('Welcome to Bhitte Patro',
                  style: AppTypography.boldTitle.copyWith(fontSize: 28)),
              const SizedBox(height: 16),
              Text('Sign in to sync your calendar and reminders.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(color: Colors.grey)),
              const Spacer(),
              if (_isLoading)
                const CircularProgressIndicator(color: AppColors.darkBlue)
              else ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    setState(() => _isLoading = true);

                    final authService = ref.read(authServiceProvider);
                    // Use the service's signOut so that the cached Google account
                    // inside AuthService is also cleared before re-authentication.
                    await authService.signOut();
                    await authService.signInWithGoogle();

                    if (mounted) setState(() => _isLoading = false);
                  },
                  icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    context.go(RoutePage.home);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkBlue,
                    side: const BorderSide(color: AppColors.darkBlue, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Continue as Guest'),
                ),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
