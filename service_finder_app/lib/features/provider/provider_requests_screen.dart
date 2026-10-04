import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../models/quotation_model.dart';
import '../../models/service_request_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/provider_request_card.dart';
import '../../widgets/request_widgets.dart';

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({super.key});

  @override
  State<ProviderRequestsScreen> createState() => _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<ProviderRequestsScreen>
    with SingleTickerProviderStateMixin {
  final _service = FirestoreService();
  late final TabController _tabs;
  Stream<List<ServiceRequestModel>>? _requests;
  Stream<List<QuotationModel>>? _quotations;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  void _load() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _requests = uid == null ? null : _service.watchProviderRequests(uid);
    _quotations = uid == null ? null : _service.watchProviderQuotations(uid);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _open(ServiceRequestModel request) async {
    final sent = await AppRouter.goToProviderRequestDetails(
      context,
      requestId: request.requestId,
    );
    if (!mounted || !sent) return;
    _tabs.animateTo(1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quotation sent. Waiting for customer approval.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Requests',
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.providerCard,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  controller: _tabs,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Received'),
                    Tab(text: 'Sent'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _requests == null
                    ? const RequestStateView(
                        title: 'Sign in to view requests',
                        message: 'Please sign in with your provider account.',
                        icon: Icons.person_outline,
                      )
                    : StreamBuilder<List<ServiceRequestModel>>(
                        key: ObjectKey(_requests),
                        stream: _requests,
                        builder: (context, requestsSnapshot) {
                          if (requestsSnapshot.hasError) return _error();
                          if (!requestsSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return StreamBuilder<List<QuotationModel>>(
                            key: ObjectKey(_quotations),
                            stream: _quotations,
                            builder: (context, quotationsSnapshot) {
                              if (quotationsSnapshot.hasError) return _error();
                              if (!quotationsSnapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final quotations = quotationsSnapshot.data!;
                              final requests = requestsSnapshot.data!;
                              final received = requests
                                  .where(
                                    (request) =>
                                        request.canReceiveQuotation &&
                                        !quotations.any(
                                          (quote) =>
                                              quote.requestId ==
                                                  request.requestId &&
                                              quote.status == 'sent',
                                        ),
                                  )
                                  .toList();
                              final byId = {
                                for (final request in requests)
                                  request.requestId: request,
                              };
                              final sent = quotations
                                  .where(
                                    (quote) =>
                                        quote.status == 'sent' &&
                                        byId[quote.requestId]
                                                ?.isAwaitingQuotationApproval ==
                                            true,
                                  )
                                  .toList();
                              return TabBarView(
                                controller: _tabs,
                                children: [
                                  received.isEmpty
                                      ? const RequestStateView(
                                          title: 'No received requests',
                                          icon: Icons.inbox_outlined,
                                        )
                                      : ListView.builder(
                                          key: const PageStorageKey(
                                            'received_requests',
                                          ),
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                            bottom: 8,
                                          ),
                                          itemCount: received.length,
                                          itemBuilder: (context, index) =>
                                              ProviderRequestCard.received(
                                                key: ValueKey(
                                                  received[index].requestId,
                                                ),
                                                request: received[index],
                                                onTap: () =>
                                                    _open(received[index]),
                                              ),
                                        ),
                                  sent.isEmpty
                                      ? const RequestStateView(
                                          title:
                                              'No quotations waiting for approval',
                                          icon: Icons.send_outlined,
                                        )
                                      : ListView.builder(
                                          key: const PageStorageKey(
                                            'sent_quotations',
                                          ),
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                            bottom: 8,
                                          ),
                                          itemCount: sent.length,
                                          itemBuilder: (context, index) {
                                            final quote = sent[index];
                                            final request =
                                                byId[quote.requestId];
                                            return ProviderRequestCard.sent(
                                              key: ValueKey(quote.quotationId),
                                              request: request,
                                              quotation: quote,
                                              onTap: () =>
                                                  AppRouter.goToProviderRequestDetails(
                                                    context,
                                                    requestId: quote.requestId,
                                                    quotationId:
                                                        quote.quotationId,
                                                  ),
                                            );
                                          },
                                        ),
                                ],
                              );
                            },
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

  Widget _error() => RequestStateView(
    title: 'Unable to load requests',
    message: 'Check your connection and try again.',
    icon: Icons.error_outline,
    onRetry: () => setState(_load),
  );
}
