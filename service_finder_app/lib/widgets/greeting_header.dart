import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Shared greeting so the customer and provider home screens always match.
class GreetingHeader extends StatelessWidget {
  final String firstName;

  const GreetingHeader({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi',
          style: textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(firstName, style: textTheme.headlineMedium),
      ],
    );
  }
}
