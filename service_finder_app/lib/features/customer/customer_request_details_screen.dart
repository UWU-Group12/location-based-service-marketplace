import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../models/review_model.dart';
import '../../models/service_request_model.dart';
import '../../services/firestore_service.dart';
import '../../services/review_service.dart';
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

  bool _isConfirming = false;

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
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(request.title, style: textTheme.headlineSmall),
        const SizedBox(height: 16),
        RequestDetailCard(
          title: 'Request',
          children: [
            RequestDetailField(
              'Status',
              requestStatusLabel(request.requestStatus),
            ),
            RequestDetailField(
              'Quotation',
              requestStatusLabel(request.quotationStatus),
            ),
            RequestDetailField('Address', request.addressText),
            RequestDetailField('Description', request.description),
            RequestDetailField(
              'Preferred date',
              requestDateLabel(context, request.preferredDate),
            ),
            RequestDetailField('Preferred time', request.preferredTime),
            RequestDetailField(
              'Created',
              requestDateTimeLabel(context, request.createdAt),
            ),
            if (request.finalAmount != null)
              RequestDetailField(
                'Agreed amount',
                'Rs. ${request.finalAmount!.toStringAsFixed(2)}',
              ),
          ],
        ),
        if (request.requestStatus == 'in_progress')
          _buildConfirmButton(context, request),
        RequestDetailCard(
          title: 'Your review',
          children: [_buildReviewSection(context, request)],
        ),
      ],
    );
  }

  Widget _buildConfirmButton(
    BuildContext context,
    ServiceRequestModel request,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: _isConfirming ? null : () => _confirmJobDone(request),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
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

        if (!snapshot.hasData) {
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
