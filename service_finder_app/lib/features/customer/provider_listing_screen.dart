import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/dummy_providers.dart';
import '../../models/service_provider_model.dart';
import '../../widgets/provider_card.dart';

class ProviderListingScreen extends StatelessWidget {
  final String service;

  const ProviderListingScreen({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {

    final textTheme = Theme.of(context).textTheme;

    final List<ServiceProviderModel> providers =
        dummyProviders.where(
          (provider) =>
              provider.service.toLowerCase() ==
              service.toLowerCase(),
        ).toList();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(service),
      ),

      body: providers.isEmpty
          ? Center(
              child: Text(
                "No providers found.",
                style: textTheme.titleMedium,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: providers.length,
              itemBuilder: (context, index) {

                final provider = providers[index];

                return ProviderCard(
                  provider: provider,
                  onTap: () {
                    // Next step:
                    // Open Provider Details Screen
                  },
                );
              },
            ),
    );
  }
}