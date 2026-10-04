import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../models/provider_model.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../widgets/provider_location_text.dart';
import '../../widgets/provider_profile_image.dart';
import '../../widgets/review_tile.dart';

class ProviderDetailsScreen extends StatefulWidget {
  final ProviderModel provider;

  const ProviderDetailsScreen({super.key, required this.provider});

  @override
  State<ProviderDetailsScreen> createState() => _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends State<ProviderDetailsScreen> {
  final ReviewService _reviewService = ReviewService();

  ProviderModel get provider => widget.provider;

  // Shared by the rating card and the reviews list
  late final Stream<List<ReviewModel>> _reviews = _reviewService
      .watchProviderReviews(provider.providerId)
      .asBroadcastStream();

  // Same average as the recomputeProviderRating Cloud Function
  String _ratingLabel(List<ReviewModel>? reviews) {
    if (reviews == null) return provider.ratingAverage.toStringAsFixed(1);
    if (reviews.isEmpty) return '0.0';
    final total = reviews.fold<double>(0, (sum, review) => sum + review.rating);
    return (total / reviews.length).toStringAsFixed(1);
  }

  String _reviewCountLabel(List<ReviewModel>? reviews) {
    final count = reviews?.length ?? provider.reviewCount;
    return count == 1 ? '1 review' : '$count reviews';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categoryNames = provider.categoryNames;
    final bio = provider.bio?.trim() ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Provider Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [_verificationBadge(), const SizedBox(width: 16)],
      ),

      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ProviderProfileImage(provider: provider, radius: 45),

                const SizedBox(height: 16),

                Text(
                  provider.displayName,
                  style: textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 6),

                Text(
                  categoryNames.join(', '),
                  style: textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),

                const SizedBox(height: 4),

                Center(child: ProviderLocationText(provider: provider)),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StreamBuilder<List<ReviewModel>>(
                      stream: _reviews,
                      builder: (context, snapshot) {
                        final reviews = snapshot.hasError
                            ? null
                            : snapshot.data;
                        return _infoCard(
                          Icons.star,
                          _ratingLabel(reviews),
                          _reviewCountLabel(reviews),
                          iconColor: AppColors.rating,
                        );
                      },
                    ),

                    _infoCard(
                      Icons.work_outline,
                      '${provider.completedJobCount} jobs',
                      'Experience',
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('About', style: textTheme.titleLarge),
                ),

                const SizedBox(height: 10),

                Text(
                  bio.isEmpty ? 'No description provided.' : bio,
                  style: textTheme.bodyMedium,
                ),

                if (categoryNames.isNotEmpty) ...[
                  const SizedBox(height: 30),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Services Offered',
                      style: textTheme.titleLarge,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ...categoryNames.map(_serviceChip),
                ],

                const SizedBox(height: 30),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Reviews', style: textTheme.titleLarge),
                ),

                const SizedBox(height: 10),

                StreamBuilder<List<ReviewModel>>(
                  stream: _reviews,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Unable to load reviews.');
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final reviews = snapshot.data!;

                    if (reviews.isEmpty) {
                      return Text(
                        'No reviews yet.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (final review in reviews.take(3))
                          ReviewTile(review: review),
                        if (reviews.length > 3)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${reviews.length - 3} more reviews',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                // Space for floating button
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Floating button only
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                AppRouter.goToCreateRequest(context, provider);
              },
              child: const Text('Request Service'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationBadge() {
    final isVerified = provider.verificationStatus == 'verified';
    final color = isVerified ? AppColors.success : AppColors.warning;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVerified ? Icons.verified : Icons.error_outline,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              isVerified ? 'Verified' : 'Pending',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    IconData icon,
    String value,
    String label, {
    Color? iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }

  Widget _serviceChip(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Chip(label: Text(title)),
      ),
    );
  }
}
