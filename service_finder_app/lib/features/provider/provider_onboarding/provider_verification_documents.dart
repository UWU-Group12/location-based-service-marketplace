import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';
import '../../../services/pref_service.dart';

class ProviderVerificationDocuments extends StatefulWidget {
  const ProviderVerificationDocuments({super.key});

  @override
  State<ProviderVerificationDocuments> createState() =>
      _ProviderVerificationDocumentsState();
}

class _ProviderVerificationDocumentsState
    extends State<ProviderVerificationDocuments> {

  bool frontUploaded = false;
  bool backUploaded = false;

  String? frontImagePath;
  String? backImagePath;

  bool get canContinue =>
      frontUploaded && backUploaded;

  void _uploadFront() {
  setState(() {
    frontUploaded = true;
    frontImagePath = "national_id_front_image";
  });
}

  void _uploadBack() {
  setState(() {
    backUploaded = true;
    backImagePath = "national_id_back_image";
  });
}

  void _submit() async {
  if (!canContinue) return;
  await PrefService.setProviderOnboardingCompleted();
  if (!mounted) return;
  AppRouter.goToProviderDashboard(context);
}

  Widget _buildUploadCard({
    required String title,
    required bool uploaded,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: uploaded
              ? AppColors.providerCard
              : AppColors.background,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: uploaded
                ? AppColors.primary
                : AppColors.border,
            width: uploaded ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              uploaded
                  ? Icons.check_circle_outline
                  : Icons.upload_file_outlined,
              size: 35,
              color: AppColors.primary,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                uploaded
                    ? "$title Uploaded"
                    : title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

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
                'assets/onboardingsvg/provider_verification.svg',
                width: 220,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 25),

            Text(
              "Verification documents",
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Upload your national ID to verify your professional profile.",
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 35),

            _buildUploadCard(
              title: "National ID Front Side",
              uploaded: frontUploaded,
              onTap: _uploadFront,
            ),

            _buildUploadCard(
              title: "National ID Back Side",
              uploaded: backUploaded,
              onTap: _uploadBack,
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: canContinue
                  ? _submit
                  : null,
              child: const Text(
                "Continue",
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}