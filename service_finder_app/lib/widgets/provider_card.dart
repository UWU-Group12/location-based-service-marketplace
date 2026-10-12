import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/provider_model.dart';
import 'provider_location_text.dart';
import 'provider_profile_image.dart';

class ProviderCard extends StatelessWidget {
  final ProviderModel provider;
  final VoidCallback onTap;

  const ProviderCard({super.key, required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final serviceNames = provider.categoryNames.join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.045)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  ProviderProfileImage(provider: provider, radius: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _RatingBadge(
                              rating: provider.ratingAverage.toStringAsFixed(1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          serviceNames,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ProviderLocationText(provider: provider),
                        Text(
                          '${provider.completedJobCount} Jobs Completed',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final String rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.rating.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 13, color: AppColors.rating),
          const SizedBox(width: 5),
          Text(
            rating,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.rating,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
