import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/provider_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/provider_card.dart';
import 'provider_details_screen.dart';

class ProviderListingScreen extends StatefulWidget {
  final String service;
  final String? categoryId;

  const ProviderListingScreen({
    super.key,
    required this.service,
    this.categoryId,
  });

  @override
  State<ProviderListingScreen> createState() => _ProviderListingScreenState();
}

class _ProviderListingScreenState extends State<ProviderListingScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  late Future<List<ProviderModel>> _providersFuture;

  @override
  void initState() {
    super.initState();
    _providersFuture = _loadProviders();
  }

  Future<List<ProviderModel>> _loadProviders() {
    return _firestoreService.getVerifiedAvailableProvidersByCategory(
      _selectedCategoryId,
    );
  }

  String get _selectedCategoryId {
    final categoryId = widget.categoryId?.trim();
    if (categoryId != null && categoryId.isNotEmpty) {
      return categoryId;
    }

    switch (widget.service.trim().toLowerCase()) {
      case 'plumbing':
        return 'plumber';
      case 'electrical':
        return 'electrician';
      case 'carpentry':
        return 'carpenter';
      case 'painting':
        return 'painter';
      default:
        return widget.service.trim().toLowerCase().replaceAll(' ', '-');
    }
  }

  void _reloadProviders() {
    setState(() => _providersFuture = _loadProviders());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(widget.service),
      ),
      body: FutureBuilder<List<ProviderModel>>(
        future: _providersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Provider search error: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 52),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load providers. Please try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _reloadProviders,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final providers = snapshot.data ?? const [];
          if (providers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No providers were found for this category.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Text(
                  '${providers.length} provider${providers.length == 1 ? '' : 's'} available',
                  style: textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];

                    return ProviderCard(
                      provider: provider,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProviderDetailsScreen(provider: provider),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
