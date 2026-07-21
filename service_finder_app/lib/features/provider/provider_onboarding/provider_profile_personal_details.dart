import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';
import '../provider_onboarding_provider.dart';

class ProviderProfilePersonalDetails extends StatefulWidget {
  const ProviderProfilePersonalDetails({super.key});

  @override
  State<ProviderProfilePersonalDetails> createState() =>
      _ProviderProfilePersonalDetailsState();
}

class _ProviderProfilePersonalDetailsState
    extends State<ProviderProfilePersonalDetails> {
  final _phoneController = TextEditingController();
  final _aboutController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _profileImageLocalPath;
  bool _initialized = false;
  bool _isPickingImage = false;

  bool get canContinue =>
      !_isPickingImage &&
      _phoneController.text.trim().isNotEmpty &&
      _aboutController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_refresh);
    _aboutController.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final onboarding = Provider.of<ProviderOnboardingProvider>(
      context,
      listen: false,
    );
    _phoneController.text = onboarding.phone;
    _aboutController.text = onboarding.about ?? '';
    _profileImageLocalPath = onboarding.profileImageLocalPath;
    _initialized = true;
  }

  void _refresh() {
    setState(() {});
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null || !mounted) return;

      setState(() => _profileImageLocalPath = image.path);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select profile image: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _continue() {
    if (!canContinue) return;

    Provider.of<ProviderOnboardingProvider>(
      context,
      listen: false,
    ).setPersonalDetails(
      phone: _phoneController.text.trim(),
      about: _aboutController.text.trim(),
      imageLocalPath: _profileImageLocalPath,
    );

    AppRouter.goToProviderProfileServiceInfo(context);
  }

  Widget _buildProfileImage() {
    final imagePath = _profileImageLocalPath;

    return Center(
      child: InkWell(
        onTap: _isPickingImage ? null : _selectImage,
        customBorder: const CircleBorder(),
        child: Container(
          width: 124,
          height: 124,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.providerCard,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: ClipOval(
            child: imagePath == null
                ? const Icon(
                    Icons.add_a_photo_outlined,
                    size: 45,
                    color: AppColors.primary,
                  )
                : Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported_outlined,
                      size: 45,
                      color: AppColors.primary,
                    ),
                  ),
          ),
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
          onPressed: _isPickingImage ? null : () => Navigator.pop(context),
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
              'Tell us about yourself',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add an optional profile photo and your provider details.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 30),
            _buildProfileImage(),
            TextButton.icon(
              onPressed: _isPickingImage ? null : _selectImage,
              icon: _isPickingImage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_library_outlined),
              label: Text(
                _profileImageLocalPath == null
                    ? 'Choose profile photo'
                    : 'Change profile photo',
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !_isPickingImage,
              decoration: InputDecoration(
                hintText: 'Mobile Number',
                prefixIcon: const Icon(Icons.phone_android_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _aboutController,
              maxLines: 4,
              enabled: !_isPickingImage,
              decoration: InputDecoration(
                hintText: 'About your services',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description_outlined),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 35),
            ElevatedButton(
              onPressed: canContinue ? _continue : null,
              child: const Text('Continue'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
