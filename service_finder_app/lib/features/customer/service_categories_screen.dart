import 'package:flutter/material.dart';
import 'package:service_finder_app/core/app_router.dart';

import '../../services/firestore_service.dart';
import '../../models/service_category_model.dart';
import '../../widgets/category_card.dart';

class ServiceCategoriesScreen extends StatefulWidget {
  const ServiceCategoriesScreen({super.key});

  @override
  State<ServiceCategoriesScreen> createState() =>
      _ServiceCategoriesScreenState();
}

class _ServiceCategoriesScreenState extends State<ServiceCategoriesScreen> {
  final FirestoreService firestoreService = FirestoreService();

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

          return LayoutBuilder(
            builder: (context, constraints) {
              const padding = 16.0;
              const spacing = 12.0;
              final availableWidth = constraints.maxWidth - (padding * 2);
              final tileWidth = (availableWidth - spacing) / 2;
              final tileHeight = CategoryCard.tileHeight(context, tileWidth);

              return GridView.builder(
                padding: const EdgeInsets.all(padding),
                itemCount: categories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: tileWidth / tileHeight,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];

                  return CategoryCard(
                    category: category,
                    onTap: () {
                      AppRouter.goToProviderListScreen(
                        context,
                        categoryId: category.id,
                        categoryName: category.name,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
