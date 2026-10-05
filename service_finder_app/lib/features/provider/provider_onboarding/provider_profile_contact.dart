import 'package:flutter/material.dart';
import 'provider_onboarding_layout.dart';
import 'package:provider/provider.dart';
import '../provider_onboarding_provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';

class ProviderProfileContact extends StatefulWidget {
  const ProviderProfileContact({super.key});

  @override
  State<ProviderProfileContact> createState() => _ProviderProfileContactState();
}

class _ProviderProfileContactState extends State<ProviderProfileContact> {
  final _emailController = TextEditingController();

  bool get canContinue => _emailController.text.trim().contains('@');

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_refresh);
  }

  void _refresh() {
    setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!canContinue) return;

    Provider.of<ProviderOnboardingProvider>(
      context,
      listen: false,
    ).setContact(email: _emailController.text.trim());

    AppRouter.goToProviderProfilePassword(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      resizeToAvoidBottomInset: true,
      body: ProviderOnboardingBody(
        padding: const EdgeInsets.symmetric(horizontal: 24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const ProviderOnboardingHeroText(
              segments: [
                ProviderOnboardingHeroSegment('Add'),
                ProviderOnboardingHeroSegment('the'),
                ProviderOnboardingHeroSegment('best', muted: true),
                ProviderOnboardingHeroSegment('way'),
                ProviderOnboardingHeroSegment('to', muted: true),
                ProviderOnboardingHeroSegment('reach'),
                ProviderOnboardingHeroSegment('you'),
              ],
            ),

            const SizedBox(height: 12),

            // Text(
            //   "We'll only use this to manage your account.",
            //   textAlign: TextAlign.center,
            //   style: textTheme.bodyLarge?.copyWith(
            //     color: AppColors.textSecondary,
            //   ),
            // ),
            const SizedBox(height: 35),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email Address",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            const SizedBox(height: 35),

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
