import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../core/widgets/floating_glass_navigation_bar.dart';
import '../../models/provider_model.dart';
import '../../models/service_category_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/customer_search_bar.dart';
import '../../widgets/featured_provider_carousel.dart';
import '../../widgets/greeting_header.dart';

class CustomerHomeScreen extends StatefulWidget {
  final String userName;
  final String initials;
  const CustomerHomeScreen({
    super.key,
    required this.userName,
    required this.initials,
  });

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<ServiceCategory>> _categoriesFuture;
  List<ServiceCategory> _allCategories = [];
  List<ServiceCategory> filteredServices = [];

  String get _firstName {
    final firstName = widget.userName.trim().split(RegExp(r'\s+')).first;
    return firstName.isEmpty ? 'User' : firstName;
  }

  @override
  void initState() {
    super.initState();
    // Fetch categories once when screen loads
    _categoriesFuture = _firestoreService.getActiveCategories().then((
      categories,
    ) {
      _allCategories = categories;
      return categories;
    });
  }

  void _searchServices(String value) {
    if (value.isEmpty) {
      setState(() {
        filteredServices = [];
      });
      return;
    }

    setState(() {
      filteredServices = _allCategories
          .where(
            (category) =>
                category.name.toLowerCase().contains(value.toLowerCase()),
          )
          .toList();
    });
  }

  Widget _buildCategoryIcon(String iconPath, {double size = 28}) {
    if (iconPath.isEmpty) {
      return Icon(Icons.home_repair_service, size: size, color: Colors.grey);
    }

    return FutureBuilder<String?>(
      future: _storageService.getDownloadUrl(iconPath),
      builder: (context, iconSnapshot) {
        if (iconSnapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (iconSnapshot.hasError || iconSnapshot.data == null) {
          return Icon(
            Icons.home_repair_service,
            size: size,
            color: Colors.grey,
          );
        }

        return Image.network(
          iconSnapshot.data!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.home_repair_service,
              size: size,
              color: Colors.grey,
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkRed = AppColors.primary.withValues(alpha: 0.8);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            FloatingGlassNavigationBar.clearanceFor(context) + 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              GreetingHeader(firstName: _firstName),
              const SizedBox(height: 25),

              // Search Bar
              Column(
                children: [
                  CustomerSearchBar(
                    controller: _searchController,
                    onChanged: _searchServices,
                  ),
                  if (filteredServices.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: filteredServices.map((category) {
                          return ListTile(
                            title: Text(category.name),
                            leading: SizedBox(
                              width: 24,
                              height: 24,
                              child: _buildCategoryIcon(
                                category.iconPath,
                                size: 24,
                              ),
                            ),
                            onTap: () {
                              _searchController.text = category.name;
                              setState(() {
                                filteredServices = [];
                              });
                              AppRouter.goToProviderListing(
                                context,
                                categoryId: category.id,
                                categoryName: category.name,
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 30),

              // Popular Services
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Popular services',
                    style: textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () {
                      AppRouter.goToServiceCategoryScreen(context);
                    },
                    child: Text(
                      'View all',
                      style: textTheme.labelLarge?.copyWith(color: darkRed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dynamic Categories from Firestore
              FutureBuilder<List<ServiceCategory>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Text('No popular services right now.');
                  }

                  // Take only the first 4 categories for the home screen row
                  final popularCategories = snapshot.data!.take(4).toList();

                  const tints = [
                    AppColors.categoryTintRose,
                    AppColors.categoryTintBlue,
                    AppColors.categoryTintAmber,
                    AppColors.categoryTintGreen,
                  ];

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(popularCategories.length, (index) {
                      final category = popularCategories[index];

                      return Expanded(
                        child: _buildServiceItem(
                          context,
                          category,
                          tints[index % tints.length],
                        ),
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: 30),
              // Nearby Professionals
              Text(
                'Available professionals',
                style: textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 15),
              StreamBuilder<List<ProviderModel>>(
                stream: _firestoreService.watchTopRatedAvailableProviders(
                  limit: 8,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Unable to load professionals right now.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final providers = snapshot.data!;

                  if (providers.isEmpty) {
                    return Text(
                      'No professionals are available right now.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    );
                  }

                  return FeaturedProviderCarousel(
                    providers: providers,
                    onViewDetails: (provider) =>
                        AppRouter.goToProviderDetails(context, provider),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(
    BuildContext context,
    ServiceCategory category,
    Color boxColor,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        AppRouter.goToProviderListing(
          context,
          categoryId: category.id,
          categoryName: category.name,
        );
      },
      child: Column(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _buildCategoryIcon(category.iconPath, size: 34),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 12,
                height: 1.1,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
