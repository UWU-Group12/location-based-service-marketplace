import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';

class BuildProfessionalProfile extends StatelessWidget {
  const BuildProfessionalProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: SvgPicture.asset(
                'assets/onboardingsvg/provider_profile1.svg',
                width: 240,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Build Your Professional Profile',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // Text(
            //   'Complete your profile to start receiving service requests from nearby customers.',
            //   textAlign: TextAlign.center,
            //   style: textTheme.bodyLarge?.copyWith(
            //     color: AppColors.textSecondary,
            //     height: 1.5,
            //   ),
            // ),
            const SizedBox(height: 36),
            _buildStepCard(
              context,
              number: '1',
              title: 'Personal Details',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 14),
            _buildStepCard(
              context,
              number: '2',
              title: 'Service Information',
              icon: Icons.design_services_outlined,
            ),
            const SizedBox(height: 14),
            _buildStepCard(
              context,
              number: '3',
              title: 'Working Area',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 14),
            _buildStepCard(
              context,
              number: '4',
              title: 'Verification Documents',
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                AppRouter.goToProviderProfilePersonalDetails(context);
              },
              child: const Text('Get Started'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required String number,
    required String title,
    required IconData icon,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: .12),
            child: Text(
              number,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Icon(
            icon,
            color: AppColors.primary,
            size: 26,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}