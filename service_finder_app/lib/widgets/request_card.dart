import 'package:flutter/material.dart';

import '../core/app_colors.dart';

import '../models/service_request_model.dart';

class RequestCard extends StatelessWidget {
  final ServiceRequestModel request;
  final VoidCallback? onTap;
  final VoidCallback? onRate;
  final String? statusLabel;

  const RequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.onRate,
    this.statusLabel,
  });

  Color _statusColor() {
    switch (request.requestStatus) {
      case 'completed':
        return AppColors.success;

      case 'confirmed':
        return AppColors.info;

      case 'quotation_received':
        return AppColors.warning;

      case 'cancelled':
        return AppColors.error;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.title, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              request.customerName == null || request.customerName!.isEmpty
                  ? 'Name unavailable'
                  : request.customerName!,
              style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (onRate != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRate,
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: const Text('Rate this job'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(request.addressText, style: textTheme.bodySmall),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel ?? request.requestStatus,
                    style: TextStyle(
                      color: _statusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
