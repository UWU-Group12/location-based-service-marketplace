import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../widgets/request_widgets.dart';

class ProviderReviewsScreen extends StatelessWidget {
  final String? providerId;

  const ProviderReviewsScreen({super.key, this.providerId});

  @override
  Widget build(BuildContext context) {
    final resolvedProviderId =
        providerId ?? FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(centerTitle: true, title: const Text('Ratings & Reviews')),
      body: resolvedProviderId == null
          ? const RequestStateView(
              title: 'Sign in to view reviews',
              message: 'Please sign in with your provider account.',
              icon: Icons.person_outline,
            )
          : StreamBuilder<List<ReviewModel>>(
              stream: ReviewService().watchProviderReviews(resolvedProviderId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const RequestStateView(
                    title: 'Unable to load reviews',
                    message: 'Check your connection and try again.',
                    icon: Icons.error_outline,
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reviews = snapshot.data!;
                if (reviews.isEmpty) {
                  return const RequestStateView(
                    title: 'No reviews yet',
                    message:
                        'Customer ratings will appear here after finished jobs.',
                    icon: Icons.star_border,
                  );
                }
                final average =
                    reviews.fold<double>(
                      0,
                      (total, review) => total + review.rating,
                    ) /
                    reviews.length;
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _ReviewsSummaryCard(
                      average: average,
                      count: reviews.length,
                    ),
                    const SizedBox(height: 16),
                    for (final review in reviews) ...[
                      _ReviewCard(review: review),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
    );
  }
}

class _ReviewsSummaryCard extends StatelessWidget {
  final double average;
  final int count;

  const _ReviewsSummaryCard({required this.average, required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.providerCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              child: Icon(Icons.star, color: AppColors.rating, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    average.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count ${count == 1 ? "review" : "reviews"}',
                    style: const TextStyle(color: AppColors.textSecondary),
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

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final comment = review.comment?.trim();
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.rating, size: 20),
                const SizedBox(width: 6),
                Text(
                  review.rating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  _dateLabel(review.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              comment == null || comment.isEmpty
                  ? 'No written review was added.'
                  : comment,
              style: TextStyle(
                color: comment == null || comment.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
