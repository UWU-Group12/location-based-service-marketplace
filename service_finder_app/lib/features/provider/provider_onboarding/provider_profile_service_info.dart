import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../provider_onboarding_provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';

class ProviderProfileServiceInfo extends StatefulWidget {
  const ProviderProfileServiceInfo({super.key});

  @override
  State<ProviderProfileServiceInfo> createState() =>
      _ProviderProfileServiceInfoState();
}

class _ProviderProfileServiceInfoState
    extends State<ProviderProfileServiceInfo> {
  String? selectedCategoryId;

  static const Map<String, String> serviceCategories = {
    'plumber': 'Plumber',
    'electrician': 'Electrician',
    'house-cleaning': 'House Cleaning',
    'home-appliance-repair': 'Home Appliance Repair',
    'carpenter': 'Carpenter',
    'painter': 'Painter',
  };

  bool get canContinue => selectedCategoryId != null;

  void _continue() {
    if (!canContinue) return;

    Provider.of<ProviderOnboardingProvider>(
      context,
      listen: false,
    ).setService(selectedCategoryId!);

    AppRouter.goToProviderProfileExperience(context);
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
                'assets/onboardingsvg/provider_service.svg',

                width: 220,

                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 25),

            Text(
              "Select your services",

              textAlign: TextAlign.center,

              style: textTheme.headlineMedium?.copyWith(
                fontSize: 32,

                fontWeight: FontWeight.w800,

                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Text(

            //   "Choose the service you provide to help customers find you.",

            //   textAlign:TextAlign.center,

            //   style:textTheme.bodyLarge?.copyWith(

            //     color:AppColors.textSecondary,

            //   ),

            // ),
            const SizedBox(height: 35),

            ...serviceCategories.entries.map((category) {
              final isSelected = selectedCategoryId == category.key;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCategoryId = category.key;
                  });
                },

                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),

                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.providerCard
                        : AppColors.background,

                    borderRadius: BorderRadius.circular(25),

                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,

                      width: isSelected ? 2 : 1,
                    ),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Text(
                        category.value,

                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,

                          color: AppColors.textPrimary,
                        ),
                      ),

                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,

                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: canContinue ? _continue : null,

              child: const Text("Continue"),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
