import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/provider_model.dart';
import 'provider_location_text.dart';
import 'provider_profile_image.dart';

class FeaturedProviderCard extends StatelessWidget {
  static const double _cardPadding = 16;
  static const double _avatarRadius = 20;

  final ProviderModel provider;
  final VoidCallback onViewDetails;

  const FeaturedProviderCard({
    super.key,
    required this.provider,
    required this.onViewDetails,
  });

  static List<String> tagsFor(ProviderModel provider) {
    return <String>[...provider.categoryNames.skip(1).take(2), 'Verified'];
  }

  static double preferredHeight(
    BuildContext context, {
    required double width,
    required ProviderModel provider,
  }) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 3.0);
    final contentWidth = width - (_cardPadding * 2);
    final tags = tagsFor(provider);
    var height = 270.0;

    // ProviderLocationText can add a padded location line in production even
    // though widget tests usually render it empty without geocoding plugins.
    if (tags.length >= 3 || (tags.length >= 2 && contentWidth < 300)) {
      height += 36;
    }
    if (_stacksHeader(textScale)) height += 24;
    if (_stacksActionRow(textScale, contentWidth)) height += 60;

    return height + (240 * (textScale - 1));
  }

  static bool _stacksHeader(double textScale) => textScale > 1.3;

  static bool _stacksActionRow(double textScale, double contentWidth) {
    return textScale > 1.3 || contentWidth < 240;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final categoryNames = provider.categoryNames;
    final title = categoryNames.isEmpty
        ? 'Service provider'
        : categoryNames.first;
    final tags = tagsFor(provider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onViewDetails,
        child: Container(
          padding: const EdgeInsets.all(_cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ProviderProfileImage(
                      provider: provider,
                      radius: _avatarRadius,
                    ),
                  ),
                  const Spacer(),
                  _RatingPill(rating: provider.ratingAverage),
                ],
              ),
              const SizedBox(height: 8),
              _stacksHeader(textScale)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProviderName(provider: provider),
                        const SizedBox(height: 4),
                        _ReviewCount(provider: provider),
                      ],
                    )
                  : Row(
                      children: [
                        Flexible(child: _ProviderName(provider: provider)),
                        const SizedBox(width: 8),
                        _ReviewCount(provider: provider),
                      ],
                    ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [for (final tag in tags) _ProviderTag(label: tag)],
              ),
              const Spacer(),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final shouldStack = _stacksActionRow(
                    textScale,
                    constraints.maxWidth,
                  );
                  final details = _ProviderCompletionDetails(
                    provider: provider,
                  );
                  final button = _ViewDetailsButton(onPressed: onViewDetails);

                  if (shouldStack) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        details,
                        const SizedBox(height: 10),
                        Align(alignment: Alignment.centerRight, child: button),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: details),
                      const SizedBox(width: 12),
                      button,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderName extends StatelessWidget {
  final ProviderModel provider;

  const _ProviderName({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Text(
      provider.displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ReviewCount extends StatelessWidget {
  final ProviderModel provider;

  const _ReviewCount({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${provider.reviewCount} reviews',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Colors.grey.shade500,
        fontSize: 12,
      ),
    );
  }
}

class _ProviderCompletionDetails extends StatelessWidget {
  final ProviderModel provider;

  const _ProviderCompletionDetails({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${provider.completedJobCount} Jobs completed',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        ProviderLocationText(provider: provider),
      ],
    );
  }
}

class _ViewDetailsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ViewDetailsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('View details'),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;

  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 15, color: AppColors.rating),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderTag extends StatelessWidget {
  final String label;

  const _ProviderTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
