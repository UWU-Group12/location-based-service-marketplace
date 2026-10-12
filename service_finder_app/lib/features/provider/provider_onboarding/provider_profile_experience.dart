import 'package:flutter/material.dart';
import 'provider_onboarding_layout.dart';

import 'package:provider/provider.dart';
import '../provider_onboarding_provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';

class ProviderProfileExperience extends StatefulWidget {
  const ProviderProfileExperience({super.key});

  @override
  State<ProviderProfileExperience> createState() =>
      _ProviderProfileExperienceState();
}

class _ProviderProfileExperienceState extends State<ProviderProfileExperience> {
  final _experienceController = TextEditingController();

  final List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  final List<String> selectedDays = [];

  int? get experienceYears => int.tryParse(_experienceController.text.trim());

  bool get canContinue =>
      experienceYears != null &&
      experienceYears! >= 0 &&
      selectedDays.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _experienceController.addListener(_refresh);
  }

  void _refresh() {
    setState(() {});
  }

  @override
  void dispose() {
    _experienceController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!canContinue) return;

    Provider.of<ProviderOnboardingProvider>(
      context,
      listen: false,
    ).setWorkingInformation(
      experienceYears: experienceYears!,
      workingDays: selectedDays,
      workingHours: 'Flexible',
    );

    AppRouter.goToProviderWorkingArea(context);
  }

  @override
  Widget build(BuildContext context) {
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
      resizeToAvoidBottomInset: true,
      body: ProviderOnboardingBody(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            const ProviderOnboardingHeroText(
              segments: [
                ProviderOnboardingHeroSegment('Tell'),
                ProviderOnboardingHeroSegment('us'),
                ProviderOnboardingHeroSegment('about', muted: true),
                ProviderOnboardingHeroSegment('your'),
                ProviderOnboardingHeroSegment('experience', muted: true),
              ],
            ),
            const SizedBox(height: 34),
            TextField(
              controller: _experienceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Years of experience",
                prefixIcon: const Icon(Icons.work_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Working Days",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: days.map((day) {
                final selected = selectedDays.contains(day);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        selectedDays.remove(day);
                      } else {
                        selectedDays.add(day);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 34),
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
