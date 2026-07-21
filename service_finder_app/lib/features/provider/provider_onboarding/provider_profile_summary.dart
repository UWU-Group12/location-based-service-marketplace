import 'package:flutter/material.dart';

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

    if (onboarding.baseLocation == null ||
        onboarding.selectedLocationId.isEmpty ||
        onboarding.serviceRadiusKm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your working area before submitting.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ProviderRegistrationService().completeProviderProfile(
        phoneNumber: onboarding.phone,
        bio: onboarding.about ?? '',
        profileImageLocalPath: onboarding.profileImageLocalPath,
        categoryId: onboarding.selectedService,
        experienceYears: onboarding.experienceYears ?? 0,
        workingDays: onboarding.workingDays,
        workingHours: onboarding.workingHours,
        baseLocation: onboarding.baseLocation!,
        locationId: onboarding.selectedLocationId,
        serviceRadiusKm: onboarding.serviceRadiusKm!,
        nationalIdFrontPath: onboarding.nationalIdFrontPath ?? '',
        nationalIdBackPath: onboarding.nationalIdBackPath ?? '',
      );

      if (!mounted) return;

      onboarding.clear();
      AppRouter.goToSignedInHome(context, user);
    } catch (error) {
      debugPrint('Provider profile completion error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not complete your provider profile. Please try again.',
            ),
          ),
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

            const Center(
              child: Icon(
                Icons.fact_check_outlined,
                size: 110,
                color: AppColors.primary,
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

                provider.phone,

                provider.profileImageLocalPath == null
                    ? "Profile image not selected"
                    : "Profile image ready for upload",

                provider.about ?? "",
              ],
            ),

            _buildSummaryCard(
              title: "Service Information",

              details: [
                _formatCategoryId(provider.selectedService),
                "${provider.experienceYears ?? 0} years experience",
                "Working days: ${provider.workingDays.join(', ')}",
                "Working hours: ${provider.workingHours}",
              ],
            ),

            _buildSummaryCard(
              title: "Working Area",
              details: [
                provider.selectedLocationName.isEmpty
                    ? "Location not selected"
                    : provider.selectedLocationName,
                provider.serviceRadiusKm == null
                    ? "Service radius not selected"
                    : "${provider.serviceRadiusKm!.toInt()} km radius",
                provider.baseLocation == null
                    ? "Current location not captured"
                    : "Current location captured",
              ],
            ),

            _buildSummaryCard(
              title: "Verification Documents",
              details: [
                provider.nationalIdFrontPath == null
                    ? "National ID front not selected"
                    : "National ID front ready for secure upload",
                provider.nationalIdBackPath == null
                    ? "National ID back not selected"
                    : "National ID back ready for secure upload",
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
