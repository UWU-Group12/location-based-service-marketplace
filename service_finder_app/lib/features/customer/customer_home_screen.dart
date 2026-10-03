import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../models/service_category_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/ai_problem_card.dart';
import 'provider_listing_screen.dart';

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
  final StorageService _storageService = StorageService(); // 👈 Added Storage Service
  final TextEditingController _searchController = TextEditingController();

  late Future<List<ServiceCategory>> _categoriesFuture;
  List<ServiceCategory> _allCategories = [];
  List<ServiceCategory> filteredServices = [];

  @override
  void initState() {
    super.initState();
    // Fetch categories once when screen loads
    _categoriesFuture = _firestoreService.getActiveCategories().then((categories) {
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

  // 👈 Helper using StorageService just like your View All screen!
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
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (iconSnapshot.hasError || iconSnapshot.data == null) {
          return Icon(Icons.home_repair_service, size: size, color: Colors.grey);
        }

        return Image.network(
          iconSnapshot.data!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.home_repair_service, size: size, color: Colors.grey);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning,',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.userName,
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 28,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            const Icon(
                              Icons.notifications_none_outlined,
                              size: 28,
                              color: Colors.black,
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                height: 8,
                                width: 8,
                                decoration: BoxDecoration(
                                  color: darkRed,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFD2B48C),
                        child: Text(
                          widget.initials,
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Search Bar
              Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _searchServices,
                    decoration: InputDecoration(
                      hintText: 'What service do you need?',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
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
                              child: _buildCategoryIcon(category.iconPath, size: 24),
                            ),
                            onTap: () {
                              _searchController.text = category.name;
                              setState(() {
                                filteredServices = [];
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProviderListingScreen(service: category.name),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 25),
              // AI Banner
              const AiProblemCard(),
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

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No popular services right now.');
                  }

                  // Take only the first 4 categories for the home screen row
                  final popularCategories = snapshot.data!.take(4).toList();

                  // Using standard soft background colors to make the colorful illustrations pop
                  final colorPairs = [
                    {'bg': const Color(0xFFFDECEC)},
                    {'bg': const Color(0xFFE3F2FD)},
                    {'bg': const Color(0xFFFFF3E0)},
                    {'bg': const Color(0xFFE8F5E9)},
                  ];

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(popularCategories.length, (index) {
                      final category = popularCategories[index];
                      final colors = colorPairs[index % colorPairs.length];

                      return Expanded(
                        child: _buildServiceItem(
                          context,
                          category,
                          colors['bg']!,
                        ),
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: 30),
              // Nearby Professionals
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available professionals',
                        style: textTheme.titleLarge?.copyWith(fontSize: 18),
                      ),
                      Text(
                        'Browse providers by service',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'See all',
                      style: textTheme.labelLarge?.copyWith(color: darkRed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Professional Card (Dummy Data - untouched)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 65,
                      width: 65,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFD8DC).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'KS',
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 20,
                          color: const Color(0xFF455A64),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Kasun Silva',
                                style: textTheme.titleMedium?.copyWith(
                                  fontSize: 17,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 6,
                                      width: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2E7D32),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Available Today',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: const Color(0xFF2E7D32),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Plumbing specialist',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFFA000),
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: textTheme.labelLarge?.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                ' (86)',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey[400],
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Badulla',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                  ],
                ),
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderListingScreen(service: category.name),
          ),
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
              // 👈 Uses the new _buildCategoryIcon which resolves the Storage Url!
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