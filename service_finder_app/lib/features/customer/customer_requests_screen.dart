import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../models/service_request_model.dart';
import '../../services/firestore_service.dart';
import '../../services/review_service.dart';
import '../../widgets/request_card.dart';

class CustomerRequestsScreen extends StatefulWidget {
  final Stream<List<ServiceRequestModel>>? requestsStream;
  final Stream<Set<String>>? reviewedRequestIdsStream;
  final Future<String?> Function(String)? loadProviderName;
  final Future<bool?> Function(String)? onRate;
  final void Function(String)? onOpenRequest;

  const CustomerRequestsScreen({
    super.key,
    this.requestsStream,
    this.reviewedRequestIdsStream,
    this.loadProviderName,
    this.onRate,
    this.onOpenRequest,
  });

  @override
  State<CustomerRequestsScreen> createState() => _CustomerRequestsScreenState();
}

class _CustomerRequestsScreenState extends State<CustomerRequestsScreen> {
  late final FirestoreService _firestoreService = FirestoreService();
  late final ReviewService _reviewService = ReviewService();
  Stream<List<ServiceRequestModel>>? _requests;
  Stream<Set<String>>? _reviews;
  final _providerNames = <String, Future<String?>>{};
  final _submittedReviews = <String>{};
  final _ratingRequests = <String>{};

  @override
  void initState() {
    super.initState();
    final customerId = widget.requestsStream == null
        ? FirebaseAuth.instance.currentUser?.uid
        : null;
    _requests =
        widget.requestsStream ??
        (customerId == null
            ? null
            : _firestoreService.watchCustomerRequests(customerId));
    _reviews =
        widget.reviewedRequestIdsStream ??
        (customerId == null
            ? null
            : _reviewService.watchReviewedRequestIds(customerId));
  }

  Future<String?> _providerName(String providerId) =>
      _providerNames.putIfAbsent(providerId, () async {
        if (providerId.trim().isEmpty) return null;
        try {
          return widget.loadProviderName != null
              ? await widget.loadProviderName!(providerId)
              : (await _firestoreService.getProviderProfile(
                  providerId,
                ))?.displayName;
        } catch (_) {
          return null;
        }
      });

  Future<void> _rate(ServiceRequestModel request) async {
    if (_ratingRequests.contains(request.requestId)) return;
    _ratingRequests.add(request.requestId);
    try {
      final saved = widget.onRate != null
          ? await widget.onRate!(request.requestId)
          : await AppRouter.goToRatingReview(context, request.requestId);
      if (mounted && saved == true) {
        setState(() => _submittedReviews.add(request.requestId));
      }
    } finally {
      _ratingRequests.remove(request.requestId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (_requests == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Text('You must sign in to see your requests.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<ServiceRequestModel>>(
          stream: _requests,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildMessage(
                icon: Icons.error_outline,
                title: 'Unable to load your requests',
                detail: 'Please check your connection and try again.',
                iconColor: AppColors.error,
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final requests = snapshot.data!;

            if (requests.isEmpty) {
              return _buildMessage(
                icon: Icons.assignment_outlined,
                title: 'No requests yet',
                detail: 'Your submitted service requests will appear here.',
              );
            }

            return StreamBuilder<Set<String>>(
              stream: _reviews,
              builder: (context, reviewSnapshot) {
                final reviewedIds = reviewSnapshot.data ?? const <String>{};

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Requests',
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Track your submitted service requests',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView.builder(
                          key: const PageStorageKey('customer_requests'),
                          padding: const EdgeInsets.only(top: 2, bottom: 8),
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final request = requests[index];
                            final isReviewable =
                                request.isFinishedJob &&
                                reviewSnapshot.hasData &&
                                !reviewSnapshot.hasError &&
                                !reviewedIds.contains(request.requestId) &&
                                !_submittedReviews.contains(request.requestId);

                            return FutureBuilder<String?>(
                              key: ValueKey(request.requestId),
                              future: _providerName(request.providerId),
                              builder: (context, providerSnapshot) =>
                                  RequestCard.customer(
                                    request: request,
                                    providerName: providerSnapshot.data,
                                    onTap: () {
                                      if (widget.onOpenRequest != null) {
                                        widget.onOpenRequest!(
                                          request.requestId,
                                        );
                                      } else {
                                        AppRouter.goToCustomerRequestDetails(
                                          context,
                                          request.requestId,
                                        );
                                      }
                                    },
                                    onRate: isReviewable
                                        ? () => _rate(request)
                                        : null,
                                  ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String detail,
    Color iconColor = Colors.grey,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 70, color: iconColor),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
