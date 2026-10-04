import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/review_model.dart';

class ReviewTile extends StatelessWidget {
  final ReviewModel review;

  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final comment = review.comment?.trim() ?? '';
    final rating = review.rating.round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var index = 1; index <= 5; index++)
                Icon(
                  index <= rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: AppColors.rating,
                ),
              const SizedBox(width: 8),
              Text(rating.toStringAsFixed(0), style: textTheme.labelLarge),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment, style: textTheme.bodyMedium),
          ],
          const SizedBox(height: 4),
          Text(
            _formatDate(review.createdAt),
            style: textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year}';
  }
}
