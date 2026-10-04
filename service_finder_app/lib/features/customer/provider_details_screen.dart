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
                    _infoCard(
                      Icons.star,
                      provider.ratingAverage.toString(),
                      'Rating',
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
                  stream: _reviewService.watchProviderReviews(
                    provider.providerId,
                  ),
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

                const SizedBox(height: 30),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Verification', style: textTheme.titleLarge),
                ),

                const SizedBox(height: 10),

                ListTile(
                  leading: Icon(
                    provider.verificationStatus == 'verified'
                        ? Icons.verified
                        : Icons.error_outline,
                    color: provider.verificationStatus == 'verified'
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  title: Text(
                    provider.verificationStatus == 'verified'
                        ? 'Verified Provider'
                        : 'Verification Pending',
                  ),
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

  Widget _infoCard(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon),
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
