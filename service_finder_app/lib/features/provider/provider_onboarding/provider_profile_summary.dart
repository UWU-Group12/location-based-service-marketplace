import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';
import '../../../services/provider_registration_service.dart';
import '../provider_onboarding_provider.dart';

class ProviderProfileSummary extends StatefulWidget {
  const ProviderProfileSummary({super.key});

  @override
  State<ProviderProfileSummary> createState() => _ProviderProfileSummaryState();
}

class _ProviderProfileSummaryState extends State<ProviderProfileSummary> {
  bool confirmed = false;
  bool _isLoading = false;

  bool get canSubmit => confirmed && !_isLoading;

  Future<void> _submit() async {
    if (!canSubmit) return;

    final onboarding = Provider.of<ProviderOnboardingProvider>(
      context,
      listen: false,
    );

    setState(() => _isLoading = true);

    try {
      final user = await ProviderRegistrationService().register(
        firstName: onboarding.firstName,
        lastName: onboarding.lastName,
        email: onboarding.email,
        phoneNumber: onboarding.phone,
        password: onboarding.password,
        bio: onboarding.about ?? '',
        categoryId: onboarding.selectedService,
      );

      if (!mounted) return;

      onboarding.clear();
      AppRouter.goToSignedInHome(context, user);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Provider registration failed: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCategoryId(String categoryId) {
    return categoryId
        .split('-')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  Widget _buildSummaryCard({
    required String title,
    required List<String> details,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppColors.providerCard,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          ...details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 6),

              child: Text(
                detail,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final provider = Provider.of<ProviderOnboardingProvider>(context);

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

          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
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
                'assets/onboardingsvg/provider_summary.svg',

                width: 220,

                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              "Review your profile",

              textAlign: TextAlign.center,

              style: textTheme.headlineMedium?.copyWith(
                fontSize: 32,

                fontWeight: FontWeight.w800,

                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Please check your information before creating your provider profile.",

              textAlign: TextAlign.center,

              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 35),

            _buildSummaryCard(
              title: "Personal Details",

              details: [
                '${provider.firstName} ${provider.lastName}'.trim().isEmpty
                    ? 'Your Google account name will be used'
                    : '${provider.firstName} ${provider.lastName}'.trim(),

                provider.email.isEmpty
                    ? "Your Google account email will be used"
                    : provider.email,

                if (provider.phone.isNotEmpty) provider.phone,

                provider.profileImagePath == null
                    ? "Profile image not selected"
                    : "Profile image selected (not uploaded)",

                provider.homeAddress?.trim().isEmpty ?? true
                    ? "Home address not provided"
                    : provider.homeAddress!,

                provider.about ?? "",
              ],
            ),

            _buildSummaryCard(
              title: "Service Information",

              details: [
                _formatCategoryId(provider.selectedService),
                "${provider.experienceYears} years experience",
                "Working days: ${provider.workingDays.join(', ')}",
                "Working hours: ${provider.workingHours}",
              ],
            ),

            _buildSummaryCard(
              title: "Working Area",
              details: [
                provider.location.isEmpty
                    ? "Location not selected"
                    : provider.location,
                "${provider.workingRadius.toInt()} km radius",
                "Location is not saved to Firebase yet",
              ],
            ),

            _buildSummaryCard(
              title: "Verification Documents",
              details: [
                provider.nationalIdFront.isEmpty
                    ? "National ID front not selected"
                    : "National ID front selected (not uploaded)",
                provider.nationalIdBack.isEmpty
                    ? "National ID back not selected"
                    : "National ID back selected (not uploaded)",
              ],
            ),

            const SizedBox(height: 10),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,

              value: confirmed,

              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        confirmed = value ?? false;
                      });
                    },

              title: const Text(
                "I confirm that the provided information is accurate.",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Create Provider Profile"),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
