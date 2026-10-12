import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../core/widgets/floating_glass_navigation_bar.dart';
import '../../models/service_request_model.dart';
import '../../services/firestore_service.dart';
import '../../services/review_service.dart';
import '../../widgets/request_card.dart';
import '../../widgets/request_widgets.dart';

class CustomerRequestsScreen extends StatefulWidget {
  // false: Requests tab (Sent / Received), true: Services tab (Active / Finished)
  final bool showServices;
  final Stream<List<ServiceRequestModel>>? requestsStream;
  final Stream<Set<String>>? reviewedRequestIdsStream;
  final Future<String?> Function(String)? loadProviderName;
  final Future<bool?> Function(String)? onRate;
  final void Function(String)? onOpenRequest;

  const CustomerRequestsScreen({
    super.key,
    this.showServices = false,
    this.requestsStream,
    this.reviewedRequestIdsStream,
    this.loadProviderName,
    this.onRate,
    this.onOpenRequest,
  });

  @override
  State<CustomerRequestsScreen> createState() => _CustomerRequestsScreenState();
}

class _CustomerRequestsScreenState extends State<CustomerRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final FirestoreService _firestoreService = FirestoreService();
  late final ReviewService _reviewService = ReviewService();
  late final TabController _tabs;
  Stream<List<ServiceRequestModel>>? _requests;
  Stream<Set<String>>? _reviews;
  final _providerNames = <String, Future<String?>>{};
  final _submittedReviews = <String>{};
  final _ratingRequests = <String>{};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
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

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
    if (_requests == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            widget.showServices
                ? 'You must sign in to see your services.'
                : 'You must sign in to see your requests.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.showServices ? 'Services' : 'Requests',
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              RequestTabBar(
                controller: _tabs,
                labels: widget.showServices
                    ? const ['Active', 'Finished']
                    : const ['Sent', 'Received'],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<ServiceRequestModel>>(
                  stream: _requests,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const RequestStateView(
                        title: 'Unable to load your requests',
                        message: 'Please check your connection and try again.',
                        icon: Icons.error_outline,
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final all = snapshot.data!;
                    // Accepted quotations become services; the rest stay requests.
                    final first = widget.showServices
                        ? all.where((r) => r.isActiveJob).toList()
                        : all
                              .where(
                                (r) =>
                                    !r.isActiveJob &&
                                    !r.isFinishedJob &&
                                    !r.isAwaitingQuotationApproval,
                              )
                              .toList();
                    final second = widget.showServices
                        ? (all.where((r) => r.isFinishedJob).toList()..sort(
                            (a, b) => b.updatedAt.compareTo(a.updatedAt),
                          ))
                        : all
                              .where((r) => r.isAwaitingQuotationApproval)
                              .toList();

                    return StreamBuilder<Set<String>>(
                      stream: _reviews,
                      builder: (context, reviewSnapshot) => TabBarView(
                        controller: _tabs,
                        children: [
                          _list(
                            first,
                            reviewSnapshot,
                            emptyTitle: widget.showServices
                                ? 'No active services'
                                : 'No sent requests',
                            emptyIcon: widget.showServices
                                ? Icons.handyman_outlined
                                : Icons.assignment_outlined,
                            storageKey: widget.showServices
                                ? 'customer_active_services'
                                : 'customer_sent_requests',
                          ),
                          _list(
                            second,
                            reviewSnapshot,
                            emptyTitle: widget.showServices
                                ? 'No finished services'
                                : 'No quotations received',
                            emptyIcon: widget.showServices
                                ? Icons.task_alt
                                : Icons.receipt_long_outlined,
                            storageKey: widget.showServices
                                ? 'customer_finished_services'
                                : 'customer_received_requests',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(
    List<ServiceRequestModel> requests,
    AsyncSnapshot<Set<String>> reviewSnapshot, {
    required String emptyTitle,
    required IconData emptyIcon,
    required String storageKey,
  }) {
    if (requests.isEmpty) {
      return RequestStateView(title: emptyTitle, icon: emptyIcon);
    }
    final reviewedIds = reviewSnapshot.data ?? const <String>{};

    return ListView.builder(
      key: PageStorageKey(storageKey),
      padding: EdgeInsets.only(
        top: 2,
        bottom: FloatingGlassNavigationBar.clearanceFor(context) + 8,
      ),
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
          builder: (context, providerSnapshot) => RequestCard.customer(
            request: request,
            providerName: providerSnapshot.data,
            onTap: () {
              if (widget.onOpenRequest != null) {
                widget.onOpenRequest!(request.requestId);
              } else {
                AppRouter.goToCustomerRequestDetails(
                  context,
                  request.requestId,
                );
              }
            },
            onRate: isReviewable ? () => _rate(request) : null,
          ),
        );
      },
    );
  }
}
