import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../provider_onboarding_provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';

class ProviderWorkingArea extends StatefulWidget {
  const ProviderWorkingArea({super.key});

  @override
  State<ProviderWorkingArea> createState() => _ProviderWorkingAreaState();
}

class _ProviderWorkingAreaState extends State<ProviderWorkingArea> {
  bool locationSelected = false;
  double radius = 5;
  String selectedLocation = '';

  bool get canContinue => locationSelected;

  void _selectLocation() {
  setState(() {
    locationSelected = true;
    selectedLocation = "Selected Location";
  });
}

  void _continue() {

  if (!canContinue) return;

  Provider.of<ProviderOnboardingProvider>(
    context,
    listen: false,
  ).setLocation(
    location: selectedLocation,
    radius: radius,
  );

  AppRouter.goToVerificationDocuments(context);

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
                'assets/onboardingsvg/provider_working_area.svg',
                width: 220,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              "Set your working area",
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // Text(
            //   "Choose where you provide your services and how far you are willing to travel.",
            //   textAlign: TextAlign.center,
            //   style: textTheme.bodyLarge?.copyWith(
            //     color: AppColors.textSecondary,
            //   ),
            // ),
            const SizedBox(height: 35),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.providerCard,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 60,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    locationSelected
                        ? "Location Selected"
                        : "Select your service location",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _selectLocation,
                    child: Text(
                      locationSelected
                          ? "Change Location"
                          : "Choose Location",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Working Radius: ${radius.toInt()} km",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Slider(
              value: radius,
              min: 1,
              max: 50,
              divisions: 49,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  radius = value;
                });
              },
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: canContinue ? _continue : null,
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