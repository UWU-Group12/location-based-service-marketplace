import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../models/provider_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../widgets/provider_card.dart';

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

enum _SortBy { nearby, rating }

class _ProviderListingScreenState extends State<ProviderListingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  late Future<List<ProviderModel>> _providersFuture;
  _SortBy _sortBy = _SortBy.nearby;
  GeoPoint? _customerLocation;

  @override
  void initState() {
    super.initState();
    _providersFuture = _loadProviders();
  }

  Future<List<ProviderModel>> _loadProviders() async {
    final locationFuture = _locationService.getCurrentOrSavedLocation();
    final providers = await _firestoreService
        .getVerifiedAvailableProvidersByCategory(_selectedCategoryId);
    _customerLocation = await locationFuture;
    return providers;
  }

  double? _distanceKm(ProviderModel provider) {
    final customer = _customerLocation;
    final base = provider.baseLocation;
    if (customer == null || base == null) return null;
    return Geolocator.distanceBetween(
          customer.latitude,
          customer.longitude,
          base.latitude,
          base.longitude,
        ) /
        1000;
  }

  int _compareRating(ProviderModel a, ProviderModel b) {
    final byRating = b.ratingAverage.compareTo(a.ratingAverage);
    return byRating != 0 ? byRating : b.reviewCount.compareTo(a.reviewCount);
  }

  // Nearby: closest first, providers without a location last.
  // Falls back to rating when the customer's location is unknown.
  List<ProviderModel> _sorted(List<ProviderModel> providers) {
    final sorted = [...providers];
    if (_sortBy == _SortBy.rating || _customerLocation == null) {
      return sorted..sort(_compareRating);
    }

    final distances = {for (final p in sorted) p: _distanceKm(p)};
    return sorted..sort((a, b) {
      final distanceA = distances[a];
      final distanceB = distances[b];
      if (distanceA == null && distanceB == null) return _compareRating(a, b);
      if (distanceA == null) return 1;
      if (distanceB == null) return -1;
      return distanceA.compareTo(distanceB);
    });
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

          final providers = _sorted(snapshot.data ?? const []);
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Nearby'),
                      avatar: const Icon(Icons.near_me_outlined, size: 18),
                      selected: _sortBy == _SortBy.nearby,
                      onSelected: (_) =>
                          setState(() => _sortBy = _SortBy.nearby),
                    ),
                    ChoiceChip(
                      label: const Text('Top rated'),
                      avatar: const Icon(Icons.star_outline, size: 18),
                      selected: _sortBy == _SortBy.rating,
                      onSelected: (_) =>
                          setState(() => _sortBy = _SortBy.rating),
                    ),
                  ],
                ),
              ),
              if (_sortBy == _SortBy.nearby && _customerLocation == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Location unavailable, showing top rated first.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _reloadProviders,
                        child: const Text('Retry'),
                      ),
                    ],
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
                      onTap: () =>
                          AppRouter.goToProviderDetails(context, provider),
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
