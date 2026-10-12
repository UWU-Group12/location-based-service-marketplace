import 'package:flutter/material.dart';

import 'provider_listing_screen.dart';

class ProviderListScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const ProviderListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderListingScreen(service: categoryName, categoryId: categoryId);
  }
}
