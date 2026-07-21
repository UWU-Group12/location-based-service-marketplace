import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';
import '../../../models/service_category_model.dart';
import '../../../services/firestore_service.dart';
import '../provider_onboarding_provider.dart';

class ProviderProfileServiceInfo extends StatefulWidget {
  const ProviderProfileServiceInfo({super.key});

  @override
  State<ProviderProfileServiceInfo> createState() =>
      _ProviderProfileServiceInfoState();
}

class _ProviderProfileServiceInfoState
    extends State<ProviderProfileServiceInfo> {
  final FirestoreService _firestoreService = FirestoreService();

  late Future<List<ServiceCategory>> _categoriesFuture;
  String? _selectedCategoryId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _firestoreService.getActiveCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final onboarding = Provider.of<ProviderOnboardingProvider>(
      context,
      listen: false,
    );
    if (onboarding.selectedService.isNotEmpty) {
      _selectedCategoryId = onboarding.selectedService;
    }
    _initialized = true;
  }

  void _reloadCategories() {
    setState(() {
      _categoriesFuture = _firestoreService.getActiveCategories();
    });
  }

  void _continue(List<ServiceCategory> categories) {
    final selectedCategoryId = _selectedCategoryId;
    final categoryIsActive = categories.any(
      (category) => category.id == selectedCategoryId,
    );

    if (selectedCategoryId == null || !categoryIsActive) return;

    Provider.of<ProviderOnboardingProvider>(
      context,
      listen: false,
    ).setService(selectedCategoryId);

    AppRouter.goToProviderProfileExperience(context);
  }

  Widget _buildCategoryList(List<ServiceCategory> categories) {
    if (categories.isEmpty) {
      return Column(
        children: [
          const Icon(
            Icons.category_outlined,
            size: 54,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No active service categories are available.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _reloadCategories,
            icon: const Icon(Icons.refresh),
            label: const Text('Reload'),
          ),
        ],
      );
    }

    final canContinue = categories.any(
      (category) => category.id == _selectedCategoryId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...categories.map((category) {
          final isSelected = _selectedCategoryId == category.id;

          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: InkWell(
              onTap: () {
                setState(() => _selectedCategoryId = category.id);
              },
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
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
                  children: [
                    const Icon(
                      Icons.design_services_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          if (category.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              category.description,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
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
            ),
          );
        }),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: canContinue ? () => _continue(categories) : null,
          child: const Text('Continue'),
        ),
      ],
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
                'assets/onboardingsvg/provider_service.svg',
                width: 220,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              'Select your service',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose the active service category that best matches your work.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 35),
            FutureBuilder<List<ServiceCategory>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  final errorMessage = snapshot.error;

                  return Column(
                    children: [
                      Text(
                        'Could not load service categories: $errorMessage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _reloadCategories,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  );
                }

                return _buildCategoryList(snapshot.data ?? const []);
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
