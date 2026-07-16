import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';

class ProviderProfilePersonalDetails extends StatefulWidget {
  const ProviderProfilePersonalDetails({super.key});

  @override
  State<ProviderProfilePersonalDetails> createState() =>
      _ProviderProfilePersonalDetailsState();
}

class _ProviderProfilePersonalDetailsState
    extends State<ProviderProfilePersonalDetails> {

  final _addressController = TextEditingController();
  final _aboutController = TextEditingController();

  bool hasProfileImage = false;

  bool get canContinue =>
      hasProfileImage &&
      _addressController.text.trim().isNotEmpty &&
      _aboutController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    _addressController.addListener(_refresh);
    _aboutController.addListener(_refresh);
  }

  void _refresh() {
    setState(() {});
  }

  @override
  void dispose() {
    _addressController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!canContinue) return;

    AppRouter.goToProviderProfileServiceInfo(context);
  }

  void _uploadImage() {
    // Image picker will be added later
    setState(() {
      hasProfileImage = true;
    });
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
                'assets/onboardingsvg/provider_personal_details.svg',
                width: 230,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 25),

            Text(
              "Tell us about yourself",
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Text(
            //   "Add your personal details so customers can know more about you.",
            //   textAlign: TextAlign.center,
            //   style: textTheme.bodyLarge?.copyWith(
            //     color: AppColors.textSecondary,
            //   ),
            // ),

            const SizedBox(height: 35),


            GestureDetector(
              onTap: _uploadImage,

              child: Center(
                child: Container(
                  width: 120,
                  height: 120,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.providerCard,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),

                  child: Icon(
                    hasProfileImage
                        ? Icons.check
                        : Icons.add_a_photo_outlined,

                    size: 45,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),


            const SizedBox(height: 35),


            TextField(
              controller: _addressController,

              maxLines: 2,

              decoration: InputDecoration(
                hintText: "Home Address",
                prefixIcon: const Icon(
                  Icons.home_outlined,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),


            const SizedBox(height: 18),


            TextField(
              controller: _aboutController,

              maxLines: 4,

              decoration: InputDecoration(
                hintText: "About",

                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(
                    Icons.description_outlined,
                  ),
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),


            const SizedBox(height: 35),


            ElevatedButton(
              onPressed: canContinue
                  ? _continue
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