import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/review_model.dart';

class ReviewTile extends StatelessWidget {
  final ReviewModel review;

  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final comment = review.comment?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ReviewTileBadge(
                      icon: Icons.star,
                      label: review.rating.toStringAsFixed(1),
                      foreground: AppColors.rating,
                      background: AppColors.rating.withValues(alpha: 0.08),
                    ),
                    const Spacer(),
                    _ReviewTileBadge(
                      icon: Icons.calendar_today_outlined,
                      label: _formatDate(review.createdAt),
                      foreground: AppColors.textSecondary,
                      background: Colors.white,
                      outlined: true,
                    ),
                  ],
                ),
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(comment, style: const TextStyle(height: 1.4)),
                ],
                if (comment.isEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'No written review was added.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year}';
  }
}

class _ReviewTileBadge extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color foreground;
  final Color background;
  final bool outlined;

  const _ReviewTileBadge({
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
