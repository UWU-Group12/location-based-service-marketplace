import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../models/provider_model.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../widgets/profile_settings.dart';
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
    final categoryNames = provider.categoryNames;
    final bio = provider.bio?.trim() ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Provider Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [_verificationBadge(), const SizedBox(width: 16)],
      ),

      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            children: [
              ProfileSettingsGroup(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProviderProfileImage(provider: provider, radius: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                categoryNames.isEmpty
                                    ? 'Category not provided'
                                    : categoryNames.join(', '),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                              ProviderLocationText(provider: provider),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _card(
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<List<ReviewModel>>(
                          stream: _reviews,
                          builder: (context, snapshot) {
                            final reviews = snapshot.hasError
                                ? null
                                : snapshot.data;
                            return _stat(
                              Icons.star,
                              _ratingLabel(reviews),
                              _reviewCountLabel(reviews),
                              iconColor: AppColors.rating,
                            );
                          },
                        ),
                      ),
                      const VerticalDivider(
                        width: 24,
                        thickness: 0.5,
                        color: AppColors.border,
                      ),
                      Expanded(
                        child: _stat(
                          Icons.work_outline,
                          '${provider.completedJobCount} jobs',
                          'Experience',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _heading('About'),
              ProfileSettingsGroup(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      bio.isEmpty ? 'No description provided.' : bio,
                      style: TextStyle(
                        height: 1.5,
                        color: bio.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              if (categoryNames.isNotEmpty) ...[
                const SizedBox(height: 24),
                _heading('Services offered'),
                ProfileSettingsGroup(
                  children: [
                    for (final name in categoryNames)
                      ProfileSettingsRow(
                        icon: Icons.home_repair_service_outlined,
                        title: name,
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              _heading('Reviews'),
              ProfileSettingsGroup(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 2),
                    child: StreamBuilder<List<ReviewModel>>(
                      stream: _reviews,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _mutedText('Unable to load reviews.');
                        }

                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final reviews = snapshot.data!;

                        if (reviews.isEmpty) {
                          return _mutedText('No reviews yet.');
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final review in reviews.take(3))
                              ReviewTile(review: review),
                            if (reviews.length > 3)
                              _mutedText('${reviews.length - 3} more reviews'),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Space for floating button
              const SizedBox(height: 100),
            ],
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

  // Same section heading as the profile screen
  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(left: 6, bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    ),
  );

  // Same bordered card as the provider dashboard
  Widget _card({required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }

  Widget _stat(
    IconData icon,
    String value,
    String label, {
    Color iconColor = AppColors.primary,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mutedText(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
  );
}
