import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../models/quotation_model.dart';
import '../../models/review_model.dart';
import '../../models/service_request_model.dart';
import '../../services/firestore_service.dart';
import '../../services/review_service.dart';
import '../../widgets/profile_settings.dart';
import '../../widgets/request_widgets.dart';
import '../../widgets/review_tile.dart';

class CustomerRequestDetailsScreen extends StatefulWidget {
  final String requestId;

  const CustomerRequestDetailsScreen({super.key, required this.requestId});

  @override
  State<CustomerRequestDetailsScreen> createState() =>
      _CustomerRequestDetailsScreenState();
}

class _CustomerRequestDetailsScreenState
    extends State<CustomerRequestDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ReviewService _reviewService = ReviewService();

  late final Stream<QuotationModel?> _quotation = _firestoreService
      .watchQuotation(widget.requestId);

  bool _isConfirming = false;
  bool _isDeciding = false;

  Future<void> _decideQuotation(QuotationModel quote, bool accept) async {
    if (_isDeciding) return;

    if (!accept) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject this quotation?'),
          content: const Text('This request will be cancelled.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _isDeciding = true;
    });

    try {
      if (accept) {
        await _firestoreService.acceptQuotation(quote);
      } else {
        await _firestoreService.rejectQuotation(quote.requestId);
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        accept
            ? 'Unable to accept this quotation. Please try again.'
            : 'Unable to reject this quotation. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeciding = false;
        });
      }
    }
  }

  Future<void> _confirmJobDone(ServiceRequestModel request) async {
    if (_isConfirming) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      await _firestoreService.confirmJobDone(request.requestId);
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        error is StateError
            ? error.message
            : 'Unable to confirm this job. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Request Details'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<ServiceRequestModel?>(
        stream: _firestoreService.watchCustomerRequest(widget.requestId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return RequestStateView(
              title: 'Unable to load this request',
              message: 'Please check your connection and try again.',
              icon: Icons.error_outline,
              onRetry: () {},
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final request = snapshot.data;

          if (request == null) {
            return const RequestStateView(
              title: 'Request unavailable',
              message:
                  'This request no longer exists or is not visible to you.',
              icon: Icons.assignment_outlined,
            );
          }

          return _buildContent(context, request);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ServiceRequestModel request) {
    final preferredVisit = [
      if (request.preferredDate != null)
        requestDateLabel(context, request.preferredDate),
      if (request.preferredTime?.trim().isNotEmpty ?? false)
        request.preferredTime!.trim(),
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        ProfileSettingsGroup(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                request.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  requestStatusLabel(request.requestStatus),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        RequestSection('Request', [
          ProfileSettingsRow(
            icon: Icons.description_outlined,
            title: 'Problem',
            value: request.description.trim().isEmpty
                ? 'Not provided'
                : request.description.trim(),
          ),
          ProfileSettingsRow(
            icon: Icons.event_outlined,
            title: 'Preferred visit',
            value: preferredVisit.isEmpty ? 'Not provided' : preferredVisit,
          ),
          if (request.finalAmount != null)
            ProfileSettingsRow(
              icon: Icons.payments_outlined,
              title: 'Agreed amount',
              value: 'Rs. ${request.finalAmount!.toStringAsFixed(2)}',
            ),
        ]),
        RequestSection('Location', [
          ProfileSettingsRow(
            icon: Icons.location_on_outlined,
            title: 'Service address',
            value: request.addressText.trim().isEmpty
                ? 'Not provided'
                : request.addressText.trim(),
          ),
          RequestLocationMap(point: request.servicePoint),
        ]),
        if (request.isAwaitingQuotationApproval)
          _buildQuotationSection(context, request),
        if (request.requestStatus == 'in_progress')
          _buildConfirmButton(context, request),
        RequestSection('Your review', [
          Padding(
            padding: const EdgeInsets.all(18),
            child: _buildReviewSection(context, request),
          ),
        ]),
      ],
    );
  }

  Widget _buildQuotationSection(
    BuildContext context,
    ServiceRequestModel request,
  ) {
    return StreamBuilder<QuotationModel?>(
      stream: _quotation,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const RequestSection('Quotation', [
            ProfileSettingsRow(
              icon: Icons.error_outline,
              title: 'Unable to load the quotation.',
            ),
          ]);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final quote = snapshot.data;

        // Only a sent quotation for this request can be decided on
        if (quote == null ||
            quote.status != 'sent' ||
            quote.requestId != request.requestId ||
            quote.customerId != request.customerId ||
            quote.providerId != request.providerId) {
          return const SizedBox.shrink();
        }

        return RequestSection('Quotation', [
          ProfileSettingsRow(
            icon: Icons.payments_outlined,
            title:
                'Estimated total: Rs. ${quote.estimatedTotal.toStringAsFixed(2)}',
            value: quote.inspectionFee == null
                ? 'Service charge Rs. ${quote.serviceCharge.toStringAsFixed(2)}'
                : 'Service charge Rs. ${quote.serviceCharge.toStringAsFixed(2)} · Inspection fee Rs. ${quote.inspectionFee!.toStringAsFixed(2)}',
          ),
          if (quote.materialCostNote?.trim().isNotEmpty ?? false)
            ProfileSettingsRow(
              icon: Icons.build_outlined,
              title: 'Material costs',
              value: quote.materialCostNote!.trim(),
            ),
          if (quote.availableAt != null)
            ProfileSettingsRow(
              icon: Icons.schedule_outlined,
              title: 'Provider available',
              value: requestDateTimeLabel(context, quote.availableAt),
            ),
          if (quote.message?.trim().isNotEmpty ?? false)
            ProfileSettingsRow(
              icon: Icons.chat_bubble_outline,
              title: 'Message',
              value: quote.message!.trim(),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isDeciding
                        ? null
                        : () => _decideQuotation(quote, false),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDeciding
                        ? null
                        : () => _decideQuotation(quote, true),
                    child: Text(_isDeciding ? 'Please wait...' : 'Accept'),
                  ),
                ),
              ],
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildConfirmButton(
    BuildContext context,
    ServiceRequestModel request,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: ElevatedButton.icon(
        onPressed: _isConfirming ? null : () => _confirmJobDone(request),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: AppColors.primary,
        ),
        icon: _isConfirming
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.task_alt),
        label: Text(_isConfirming ? 'Confirming...' : 'Job is done'),
      ),
    );
  }

  Widget _buildReviewSection(
    BuildContext context,
    ServiceRequestModel request,
  ) {
    if (!request.isFinishedJob) {
      return Text(
        request.requestStatus == 'in_progress'
            ? 'Confirm the job is done to leave a review.'
            : 'You can leave a review once this job is completed.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }

    return StreamBuilder<ReviewModel?>(
      stream: _reviewService.watchReview(request.requestId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Unable to load your review.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final review = snapshot.data;

        if (review == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate the work you received.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    AppRouter.goToRatingReview(context, request.requestId),
                icon: const Icon(Icons.star_outline),
                label: const Text('Rate this job'),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReviewTile(review: review),
            const SizedBox(height: 8),
            Text(
              'A review can only be submitted once per job.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        );
      },
    );
  }
}
