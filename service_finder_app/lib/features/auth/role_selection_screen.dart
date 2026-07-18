import 'package:flutter/material.dart';

import '../../core/app_router.dart';
import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _selectRole(bool isProvider) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentProfile = await _authService.getUserProfileForCurrentUser();

      if (!mounted) return;

      if (currentProfile != null) {
        AppRouter.goToSignedInHome(
          context,
          currentProfile,
          signedInWithGoogle: _authService.currentUserUsesGoogle,
        );
        return;
      }

      if (_authService.hasAuthenticatedUser) {
        final role = isProvider ? UserRole.provider : UserRole.customer;
        final newProfile = await _authService.createCurrentUserProfile(role);

        if (!mounted) return;

        AppRouter.goToSignedInHome(
          context,
          newProfile,
          signedInWithGoogle: _authService.currentUserUsesGoogle,
        );
        return;
      }

      if (isProvider) {
        AppRouter.goToProviderProfileName(context);
      } else {
        AppRouter.goToCustomerRegister(context);
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your role: $error')),
      );
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
    final darkRed = AppColors.primary;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Text(
              'Select\nuser type',
              style: textTheme.headlineLarge?.copyWith(
                fontSize: 40,
                color: darkRed,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 110),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildRoleCard(
                      context: context,
                      role: 'Service\nProvider',
                      description: 'Offer your professional services',
                      imagePath: 'assets/images/provider.png',
                      isProvider: true,
                      cardColor: AppColors.providerCard,
                    ),
                    const SizedBox(height: 25),
                    _buildRoleCard(
                      context: context,
                      role: 'Customer',
                      description: 'Find the best services near you',
                      imagePath: 'assets/images/client.png',
                      isProvider: false,
                      cardColor: AppColors.customerCard,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String role,
    required String description,
    required String imagePath,
    required bool isProvider,
    required Color cardColor,
  }) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _isLoading ? null : () => _selectRole(isProvider),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person,
                      size: 80,
                      color: AppColors.border,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontSize: 24,
                              color: AppColors.textPrimary,
                              height: 1.1,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
