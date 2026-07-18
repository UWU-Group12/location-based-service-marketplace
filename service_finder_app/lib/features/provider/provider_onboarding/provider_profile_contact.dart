import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final _phoneController = TextEditingController();

  bool get canContinue =>
      _emailController.text.trim().contains('@') &&
      _phoneController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_refresh);
    _phoneController.addListener(_refresh);
  }

  void _refresh() {
    setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!canContinue) return;

    Provider.of<ProviderOnboardingProvider>(context, listen: false).setContact(
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    AppRouter.goToProviderProfilePassword(context);
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
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            Center(
              child: SvgPicture.asset(
                'assets/onboardingsvg/provider_contact.svg',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 35),

            Text(
              "Add the best way to reach you.",
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
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
                labelText: "Email Address (Optional)",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Mobile Number",
                prefixIcon: const Icon(Icons.phone_android_outlined),
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
