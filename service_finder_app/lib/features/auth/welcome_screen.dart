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

      AppRouter.goToSignedInHome(
        context,
        userProfile,
        signedInWithGoogle: _authService.currentUserUsesGoogle,
      );
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildIllustration(),
                      const SizedBox(height: 36),
                      Text(
                        'Find trusted professionals',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineLarge?.copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connect with skilled service providers around you in minutes.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildIllustration() {
    return Center(
      child: Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          color: AppColors.providerCard,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.handyman_rounded,
          size: 88,
          color: AppColors.primary,
        ),
      ),
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
