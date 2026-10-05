import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../services/auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _continueWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithGoogle();

      if (result == null) {
        return;
      }

      final firebaseUser = result.user;
      if (firebaseUser == null) {
        throw StateError('Firebase did not return the Google user.');
      }

      final existingProfile = await _authService.getUserProfile(
        firebaseUser.uid,
      );

      if (!mounted) return;

      if (existingProfile == null) {
        AppRouter.goToRoleSelection(context);
        return;
      }

      final userProfile = await _authService.requireActiveUserProfile(
        firebaseUser.uid,
      );

      if (!mounted) return;

      AppRouter.goToSignedInHome(context, userProfile);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google Sign-In failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 48).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/icons/applogo3.png',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Same two-line style as the dashboard GreetingHeader.
                      Text(
                        'Welcome to',
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Raw',
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Find trusted professionals around you in minutes.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // R = Request, A = Arrange, W = Work
                      _card(
                        child: Column(
                          children: [
                            _meaningRow(
                              Icons.assignment_outlined,
                              'R',
                              'equest',
                              'Describe the job you need done',
                            ),
                            const Divider(height: 28),
                            _meaningRow(
                              Icons.event_available_outlined,
                              'A',
                              'rrange',
                              'Compare quotes and pick a time',
                            ),
                            const Divider(height: 28),
                            _meaningRow(
                              Icons.handyman_outlined,
                              'W',
                              'ork',
                              'A trusted pro gets it done',
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 32),
                      _buildPrimaryButton(
                        context: context,
                        label: 'Create Account',
                        onPressed: _isLoading
                            ? null
                            : () => AppRouter.goToRoleSelection(context),
                      ),
                      const SizedBox(height: 14),
                      _buildOutlinedButton(
                        context: context,
                        label: 'Sign In',
                        onPressed: _isLoading
                            ? null
                            : () => AppRouter.goToLogin(context),
                      ),
                      const SizedBox(height: 14),
                      _buildGoogleButton(
                        context: context,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _continueWithGoogle,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // White bordered card, same as the provider dashboard cards.
  Widget _card({required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }

  // One letter of the name, e.g. "R" + "equest" with a short explanation.
  Widget _meaningRow(IconData icon, String letter, String rest, String detail) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: letter,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(text: rest),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required BuildContext context,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }

  Widget _buildOutlinedButton({
    required BuildContext context,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildGoogleButton({
    required BuildContext context,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 2,
          shadowColor: Colors.black12,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'G',
                      style: textStyle?.copyWith(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Continue with Google', style: textStyle),
                ],
              ),
      ),
    );
  }
}
