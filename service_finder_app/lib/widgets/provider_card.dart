import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/service_provider_model.dart';

class ProviderCard extends StatelessWidget {
  final ServiceProviderModel provider;
  final VoidCallback onTap;

  const ProviderCard({
    super.key,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.providerCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Row(
          children: [

            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              child: Text(
                provider.name[0],
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [

                      Expanded(
                        child: Text(
                          provider.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      if (provider.isVerified)
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 20,
                        ),

                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    provider.service,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [

                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        provider.location,
                        style: textTheme.bodySmall,
                      ),

                      const Spacer(),

                      const Icon(
                        Icons.star,
                        size: 18,
                        color: Colors.amber,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        provider.rating.toString(),
                        style: textTheme.bodySmall,
                      ),

                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "${provider.experience} Years Experience",
                    style: textTheme.bodySmall,
                  ),

                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}