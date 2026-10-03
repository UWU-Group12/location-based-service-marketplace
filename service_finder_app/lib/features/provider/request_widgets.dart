import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

String requestStatusLabel(String value) => value
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

String requestDateLabel(BuildContext context, DateTime? value) =>
    value == null || value.millisecondsSinceEpoch == 0
    ? 'Not provided'
    : MaterialLocalizations.of(context).formatMediumDate(value.toLocal());

String requestDateTimeLabel(BuildContext context, DateTime? value) =>
    value == null || value.millisecondsSinceEpoch == 0
    ? 'Not provided'
    : '${requestDateLabel(context, value)} at ${TimeOfDay.fromDateTime(value.toLocal()).format(context)}';

class RequestStateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  const RequestStateView({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
        ],
      ),
    ),
  );
}

class RequestDetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const RequestDetailCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

class RequestDetailField extends StatelessWidget {
  final String label;
  final String? value;

  const RequestDetailField(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value == null || value!.trim().isEmpty ? 'Not provided' : value!,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    ),
  );
}
