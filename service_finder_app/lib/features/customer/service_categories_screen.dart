import 'package:flutter/material.dart';
import 'package:service_finder_app/core/app_router.dart';

import '../../services/firestore_service.dart';
import '../../models/service_category_model.dart';
import '../../services/storage_service.dart';

class ServiceCategoriesScreen extends StatefulWidget {
  const ServiceCategoriesScreen({super.key});

  @override
  State<ServiceCategoriesScreen> createState() =>
      _ServiceCategoriesScreenState();
}

class _ServiceCategoriesScreenState extends State<ServiceCategoriesScreen> {
  final FirestoreService firestoreService = FirestoreService();
  final StorageService storageService = StorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Categories')),
      body: FutureBuilder<List<ServiceCategory>>(
        future: firestoreService.getActiveCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Category error: ${snapshot.error}');
            return const Center(child: Text("Unable to Load Categories"));
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return const Center(child: Text("No Categories"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];

              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: (){ AppRouter.goToProviderListScreen(context,category.name);},
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: category.iconPath.isEmpty
                              ? const Icon(Icons.home_repair_service, size: 42)
                              : FutureBuilder<String?>(
                                  future: storageService.getDownloadUrl(
                                    category.iconPath,
                                  ),
                                  builder: (context, iconSnapshot) {
                                    if (iconSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      );
                                    }

                                    if (iconSnapshot.hasError ||
                                        iconSnapshot.data == null) {
                                      return const Icon(
                                        Icons.home_repair_service,
                                        size: 42,
                                      );
                                    }

                                    return Image.network(
                                      iconSnapshot.data!,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.home_repair_service,
                                              size: 42,
                                            );
                                          },
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          category.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
