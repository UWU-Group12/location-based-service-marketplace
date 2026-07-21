import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';
import '../provider_onboarding_provider.dart';

class ProviderVerificationDocuments extends StatefulWidget {
  const ProviderVerificationDocuments({super.key});

  @override
  State<ProviderVerificationDocuments> createState() =>
      _ProviderVerificationDocumentsState();
}

class _ProviderVerificationDocumentsState
    extends State<ProviderVerificationDocuments> {
  final ImagePicker _imagePicker = ImagePicker();

  String? _frontImagePath;
  String? _backImagePath;
  bool _initialized = false;
  bool _isPickingImage = false;

  bool get canContinue =>
      _frontImagePath != null && _backImagePath != null && !_isPickingImage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final onboarding = Provider.of<ProviderOnboardingProvider>(
      context,
      listen: false,
    );
    _frontImagePath = onboarding.nationalIdFrontPath;
    _backImagePath = onboarding.nationalIdBackPath;
    _initialized = true;
  }

  Future<void> _pickDocument({required bool isFront}) async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2000,
      );

      if (image == null || !mounted) return;

      setState(() {
        if (isFront) {
          _frontImagePath = image.path;
        } else {
          _backImagePath = image.path;
        }
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select the image: $error')),
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
    ).setVerificationDocuments(
      nationalIdFrontPath: _frontImagePath!,
      nationalIdBackPath: _backImagePath!,
    );

    AppRouter.goToProviderProfileSummary(context);
  }

  String _fileName(String path) {
    return path.replaceAll(r'\', '/').split('/').last;
  }

  Widget _buildUploadCard({
    required String title,
    required String? imagePath,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final selected = imagePath != null;

    return InkWell(
      onTap: _isPickingImage ? null : onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.providerCard : AppColors.background,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (selected)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath),
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: 64,
                    height: 64,
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              )
            else
              const SizedBox(
                width: 64,
                height: 64,
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected ? '$title selected' : title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(height: 4),
                    Text(
                      _fileName(imagePath),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              selected ? Icons.edit_outlined : Icons.arrow_forward_ios,
              size: 20,
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
            const SizedBox(height: 18),
            const Icon(
              Icons.verified_user_outlined,
              size: 110,
              color: AppColors.primary,
            ),
            const SizedBox(height: 25),
            Text(
              'Verification documents',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select clear images of both sides of your National ID. '
              'They are uploaded securely when you create your profile.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 35),
            _buildUploadCard(
              title: 'National ID front side',
              imagePath: _frontImagePath,
              onTap: () => _pickDocument(isFront: true),
            ),
            _buildUploadCard(
              title: 'National ID back side',
              imagePath: _backImagePath,
              onTap: () => _pickDocument(isFront: false),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: canContinue ? _continue : null,
              child: _isPickingImage
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continue'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
