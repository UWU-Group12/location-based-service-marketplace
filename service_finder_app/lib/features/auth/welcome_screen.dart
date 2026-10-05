import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 50).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Raw',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.22),
                    const _HeroHeadline(),
                    const SizedBox(height: 32),
                    _buildPrimaryButton(
                      context: context,
                      label: 'Create Account',
                      onPressed: _isLoading
                          ? null
                          : () => AppRouter.goToRoleSelection(context),
                    ),
                    const SizedBox(height: 12),
                    _buildOutlinedButton(
                      context: context,
                      label: 'Sign In',
                      onPressed: _isLoading
                          ? null
                          : () => AppRouter.goToLogin(context),
                    ),
                    const SizedBox(height: 12),
                    _buildGoogleButton(
                      context: context,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _continueWithGoogle,
                    ),
                  ],
                ),
              ),
            );
          },
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
                  SvgPicture.asset(
                    'assets/icons/google.svg',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 12),
                  Text('Continue with Google', style: textStyle),
                ],
              ),
      ),
    );
  }
}

class _HeroHeadline extends StatelessWidget {
  const _HeroHeadline();

  static const _black = TextStyle(
    color: AppColors.primary,
    fontSize: 34,
    height: 1.08,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
  );

  static final _gray = _black.copyWith(
    color: AppColors.textPrimary.withValues(alpha: 0.34),
  );

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Request ', style: _black),
          TextSpan(text: 'what you need\n', style: _gray),
          TextSpan(text: 'Arrange ', style: _gray),
          const TextSpan(text: 'with professionals\n', style: _black),
          const TextSpan(text: 'Work ', style: _black),
          TextSpan(text: 'together', style: _gray),
        ],
      ),
      textAlign: TextAlign.left,
    );
  }
}
