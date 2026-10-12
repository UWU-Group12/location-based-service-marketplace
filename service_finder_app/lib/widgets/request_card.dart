import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/quotation_model.dart';
import '../models/service_request_model.dart';

enum _CardKind { received, sent, job, customer }

class RequestCard extends StatelessWidget {
  final ServiceRequestModel? request;
  final QuotationModel? quotation;
  final VoidCallback? onTap;
  final VoidCallback? onRate;
  final String? statusLabel;
  final String? providerName;
  final _CardKind _kind;

  const RequestCard({
    super.key,
    required ServiceRequestModel this.request,
    this.onTap,
    this.statusLabel,
  }) : quotation = null,
       onRate = null,
       providerName = null,
       _kind = _CardKind.job;

  const RequestCard.customer({
    super.key,
    required ServiceRequestModel this.request,
    required this.providerName,
    this.onTap,
    this.onRate,
  }) : quotation = null,
       statusLabel = null,
       _kind = _CardKind.customer;

  const RequestCard.received({
    super.key,
    required ServiceRequestModel this.request,
    required this.onTap,
  }) : quotation = null,
       onRate = null,
       statusLabel = null,
       providerName = null,
       _kind = _CardKind.received;

  const RequestCard.sent({
    super.key,
    required this.request,
    required QuotationModel this.quotation,
    required this.onTap,
  }) : onRate = null,
       statusLabel = null,
       providerName = null,
       _kind = _CardKind.sent;

  String get _statusLabel {
    if (_kind == _CardKind.received) return 'Received';
    if (_kind == _CardKind.sent) return 'Awaiting approval';
    if (statusLabel != null) return statusLabel!;
    return switch (request?.requestStatus) {
      'submitted' => 'Submitted',
      'quotation_received' => 'Quotation received',
      'confirmed' => 'Confirmed',
      'in_progress' => 'In progress',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      'provider_rejected' => 'Declined',
      _ => 'Status unavailable',
    };
  }

  Color get _statusColor {
    if (_kind == _CardKind.received) return AppColors.textSecondary;
    if (_kind == _CardKind.sent) return AppColors.primary;
    return switch (request?.requestStatus) {
      'completed' => Colors.green.shade700,
      'confirmed' => Colors.blue.shade700,
      'quotation_received' => Colors.orange.shade800,
      'in_progress' => AppColors.primary,
      'cancelled' || 'provider_rejected' => Colors.red.shade700,
      _ => AppColors.textSecondary,
    };
  }

  IconData get _statusIcon => switch (_kind) {
    _CardKind.received => Icons.inbox_outlined,
    _CardKind.sent => Icons.schedule_outlined,
    _ => switch (request?.requestStatus) {
      'completed' => Icons.task_alt,
      'in_progress' => Icons.work_outline,
      'confirmed' => Icons.check_circle_outline,
      'cancelled' || 'provider_rejected' => Icons.cancel_outlined,
      _ => Icons.schedule_outlined,
    },
  };

  String _amount(double value) {
    if (!value.isFinite || value < 0) return 'Amount unavailable';
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return 'Rs. $whole.${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    final title = request?.title.trim();
    final location = request?.addressText.trim();
    final name =
        (_kind == _CardKind.customer ? providerName : request?.customerName)
            ?.trim();
    final date = switch (_kind) {
      _CardKind.sent => quotation?.createdAt,
      _CardKind.job => request?.updatedAt,
      _ => request?.createdAt,
    };
    final dateAction = switch (_kind) {
      _CardKind.received => 'Request received',
      _CardKind.sent => 'Quotation sent',
      _CardKind.job => 'Job updated',
      _CardKind.customer => 'Request submitted',
    };
    final amount =
        quotation?.estimatedTotal ??
        ((request?.isActiveJob == true || request?.isFinishedJob == true)
            ? request?.finalAmount
            : null);
    final canRate =
        _kind == _CardKind.customer &&
        request?.isFinishedJob == true &&
        onRate != null;
    final localizations = MaterialLocalizations.of(context);
    final hasDate = date != null && date.millisecondsSinceEpoch != 0;
    final dateLabel = hasDate
        ? localizations.formatShortMonthDay(date.toLocal())
        : 'Date unavailable';
    final dateDescription = hasDate
        ? '$dateAction on ${localizations.formatMediumDate(date.toLocal())}'
        : '$dateAction date unavailable';

    final badges = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _CardBadge(
          icon: _statusIcon,
          label: _statusLabel,
          foreground: _statusColor,
          background: _statusColor.withValues(alpha: 0.06),
        ),
        if (amount != null)
          _CardBadge(
            label: _amount(amount),
            foreground: AppColors.onTintPrimary,
            background: AppColors.providerCard,
          ),
      ],
    );

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
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!canRate)
                    badges
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final rateButton = FilledButton.icon(
                          onPressed: onRate,
                          icon: const Icon(Icons.star_outline, size: 15),
                          label: const Text('Rate'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: const StadiumBorder(),
                          ),
                        );
                        if (constraints.maxWidth < 240 ||
                            MediaQuery.textScalerOf(context).scale(12) > 16) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: rateButton,
                              ),
                              const SizedBox(height: 8),
                              badges,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: badges),
                            const SizedBox(width: 10),
                            rateButton,
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 14),
                  Text(
                    title == null || title.isEmpty
                        ? 'Request unavailable'
                        : title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          location == null || location.isEmpty
                              ? 'Location unavailable'
                              : location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Divider(
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.045),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final customer = _CounterpartLabel(
                        name: name,
                        fallback: _kind == _CardKind.customer
                            ? 'Provider unavailable'
                            : 'Name unavailable',
                      );
                      final dateChip = Tooltip(
                        message: dateDescription,
                        child: _CardBadge(
                          icon: Icons.calendar_today_outlined,
                          label: dateLabel,
                          foreground: AppColors.textSecondary,
                          background: Colors.white,
                          outlined: true,
                        ),
                      );
                      if (constraints.maxWidth < 240 ||
                          MediaQuery.textScalerOf(context).scale(12) > 16) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            customer,
                            const SizedBox(height: 10),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: dateChip,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: customer),
                          const SizedBox(width: 12),
                          dateChip,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color foreground;
  final Color background;
  final bool outlined;

  const _CardBadge({
    this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) => Container(
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

class _CounterpartLabel extends StatelessWidget {
  final String? name;
  final String fallback;
  const _CounterpartLabel({this.name, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final words = (name ?? '')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? ''
        : '${words.first.characters.first}${words.length > 1 ? words.last.characters.first : ''}'
              .toUpperCase();
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFFF0F0F2),
          child: initials.isEmpty
              ? const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                )
              : Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            words.isEmpty ? fallback : name!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
