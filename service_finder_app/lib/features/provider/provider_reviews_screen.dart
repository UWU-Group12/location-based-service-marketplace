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
    return _SoftReviewCard(
      color: AppColors.providerCard,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(Icons.star, color: AppColors.rating, size: 24),
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ReviewBadge(
                        icon: Icons.star,
                        label: 'Average rating',
                        foreground: AppColors.rating,
                        background: Colors.white,
                        outlined: true,
                      ),
                      _ReviewBadge(
                        label: '$count ${count == 1 ? "review" : "reviews"}',
                        foreground: AppColors.textSecondary,
                        background: Colors.white,
                        outlined: true,
                      ),
                    ],
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
    return _SoftReviewCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ReviewBadge(
                  icon: Icons.star,
                  label: review.rating.toStringAsFixed(1),
                  foreground: AppColors.rating,
                  background: AppColors.rating.withValues(alpha: 0.08),
                ),
                const Spacer(),
                _ReviewBadge(
                  icon: Icons.calendar_today_outlined,
                  label: _dateLabel(review.createdAt),
                  foreground: AppColors.textSecondary,
                  background: Colors.white,
                  outlined: true,
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

class _SoftReviewCard extends StatelessWidget {
  final Widget child;
  final Color color;

  const _SoftReviewCard({required this.child, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.045)),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _ReviewBadge extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color foreground;
  final Color background;
  final bool outlined;

  const _ReviewBadge({
    this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
        border: outlined
            ? Border.all(color: Colors.black.withValues(alpha: 0.06))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: foreground,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
