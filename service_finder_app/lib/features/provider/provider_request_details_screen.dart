import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_router.dart';
import '../../models/quotation_model.dart';
import '../../models/service_request_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import 'request_widgets.dart';

class ProviderRequestDetailsScreen extends StatefulWidget {
  final String requestId;
  final String? quotationId;

  const ProviderRequestDetailsScreen({
    super.key,
    required this.requestId,
    this.quotationId,
  });

  @override
  State<ProviderRequestDetailsScreen> createState() =>
      _ProviderRequestDetailsScreenState();
}

class _ProviderRequestDetailsScreenState
    extends State<ProviderRequestDetailsScreen> {
  final _service = FirestoreService();
  Stream<ServiceRequestModel?>? _request;
  Stream<QuotationModel?>? _quotation;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _request = uid == null
        ? null
        : _service.watchProviderRequest(widget.requestId, uid);
    _quotation = uid == null ? null : _service.watchQuotation(widget.requestId);
  }

  Future<void> _createQuotation(ServiceRequestModel request) async {
    final sent = await AppRouter.goToCreateQuotation(context, request);
    if (!mounted || !sent) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.quotationId == null ? 'Request details' : 'Sent quotation',
      ),
    ),
    body: _request == null
        ? const RequestStateView(
            title: 'Sign in required',
            message: 'Please sign in with your provider account.',
            icon: Icons.person_outline,
          )
        : StreamBuilder<ServiceRequestModel?>(
            key: ObjectKey(_request),
            stream: _request,
            builder: (context, snapshot) {
              if (snapshot.hasError) return _error('Unable to load request');
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final request = snapshot.data;
              if (request == null) {
                return const RequestStateView(
                  title: 'Request unavailable',
                  message:
                      'This request no longer exists or is not assigned to you.',
                  icon: Icons.assignment_outlined,
                );
              }
              return StreamBuilder<QuotationModel?>(
                key: ObjectKey(_quotation),
                stream: _quotation,
                builder: (context, quoteSnapshot) {
                  if (quoteSnapshot.hasError) {
                    return _error('Unable to load quotation');
                  }
                  if (quoteSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // A null document is expected before the first quotation.
                  final quote = quoteSnapshot.data;
                  if (quote != null &&
                      (quote.providerId != request.providerId ||
                          quote.customerId != request.customerId ||
                          quote.requestId != request.requestId)) {
                    return _error('Quotation does not match this request');
                  }
                  final hasSentQuote = quote?.status == 'sent';
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        request.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      RequestDetailCard(
                        title: 'Customer',
                        children: [
                          RequestDetailField(
                            'Customer Name',
                            request.customerName == null ||
                                    request.customerName!.trim().isEmpty
                                ? 'Name unavailable'
                                : request.customerName,
                          ),
                        ],
                      ),
                      RequestDetailCard(
                        title: 'Request',
                        children: [
                          RequestDetailField(
                            'Customer problem',
                            request.description,
                          ),
                          RequestDetailField(
                            'Request status',
                            requestStatusLabel(request.requestStatus),
                          ),
                          RequestDetailField(
                            'Quotation status',
                            requestStatusLabel(request.quotationStatus),
                          ),
                          RequestDetailField(
                            'Service category',
                            request.categoryId,
                          ),

                          RequestDetailField(
                            'Requested on',
                            requestDateTimeLabel(context, request.createdAt),
                          ),

                          if (request.finalAmount != null)
                            RequestDetailField(
                              'Final amount',
                              'Rs. ${request.finalAmount!.toStringAsFixed(2)}',
                            ),
                        ],
                      ),
                      RequestDetailCard(
                        title: 'Location and preferred visit',
                        children: [
                          RequestDetailField(
                            'Service address',
                            request.addressText,
                          ),
                          RequestDetailField(
                            'Coordinates',
                            '${request.servicePoint.latitude}, ${request.servicePoint.longitude}',
                          ),
                          RequestDetailField(
                            'Preferred date',
                            requestDateLabel(context, request.preferredDate),
                          ),
                          RequestDetailField(
                            'Preferred time',
                            request.preferredTime,
                          ),
                        ],
                      ),
                      RequestDetailCard(
                        title: 'Request images',
                        children: [
                          if (request.imagePaths == null ||
                              request.imagePaths!.isEmpty)
                            const Text('No images provided.')
                          else
                            ...request.imagePaths!.map(
                              (path) => _RequestImage(
                                key: ValueKey(path),
                                path: path,
                              ),
                            ),
                        ],
                      ),
                      if (quote != null)
                        RequestDetailCard(
                          title: 'Quotation sent',
                          children: [
                            RequestDetailField(
                              'Approval status',
                              quote.status == 'sent'
                                  ? (request.isAwaitingQuotationApproval
                                        ? 'Waiting for customer approval'
                                        : 'Sent - request ${requestStatusLabel(request.requestStatus).toLowerCase()}')
                                  : requestStatusLabel(quote.status),
                            ),
                            RequestDetailField(
                              'Service charge',
                              'Rs. ${quote.serviceCharge.toStringAsFixed(2)}',
                            ),
                            RequestDetailField(
                              'Inspection fee',
                              'Rs. ${(quote.inspectionFee ?? 0).toStringAsFixed(2)}',
                            ),
                            RequestDetailField(
                              'Estimated total',
                              'Rs. ${quote.estimatedTotal.toStringAsFixed(2)}',
                            ),
                            RequestDetailField(
                              'Material costs',
                              quote.materialCostNote,
                            ),
                            RequestDetailField(
                              'Message to customer',
                              quote.message,
                            ),
                            RequestDetailField(
                              'Available visit',
                              requestDateTimeLabel(context, quote.availableAt),
                            ),
                            RequestDetailField(
                              'Expires on',
                              requestDateTimeLabel(context, quote.expiresAt),
                            ),
                            RequestDetailField(
                              'Sent on',
                              requestDateTimeLabel(context, quote.createdAt),
                            ),
                            RequestDetailField(
                              'Last updated',
                              requestDateTimeLabel(context, quote.updatedAt),
                            ),
                          ],
                        ),
                      if (widget.quotationId != null && quote == null)
                        const RequestDetailCard(
                          title: 'Quotation unavailable',
                          children: [
                            Text('This quotation is no longer available.'),
                          ],
                        ),
                      if (request.canReceiveQuotation &&
                          !hasSentQuote &&
                          widget.quotationId == null)
                        ElevatedButton.icon(
                          onPressed: () => _createQuotation(request),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('Create quotation'),
                        ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              );
            },
          ),
  );

  Widget _error(String title) => RequestStateView(
    title: title,
    message: 'Check your connection and access, then try again.',
    icon: Icons.error_outline,
    onRetry: () => setState(_load),
  );
}

class _RequestImage extends StatefulWidget {
  final String path;
  const _RequestImage({super.key, required this.path});

  @override
  State<_RequestImage> createState() => _RequestImageState();
}

class _RequestImageState extends State<_RequestImage> {
  late Future<String> _url;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _url =
        widget.path.startsWith('https://') || widget.path.startsWith('http://')
        ? Future.value(widget.path)
        : StorageService().getDownloadUrl(widget.path);
  }

  Widget _failure() => TextButton.icon(
    onPressed: () => setState(_load),
    icon: const Icon(Icons.broken_image_outlined),
    label: const Text('Image unavailable. Try again'),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: FutureBuilder<String>(
      future: _url,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _failure();
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => Dialog.fullscreen(
              child: Scaffold(
                appBar: AppBar(title: const Text('Request image')),
                body: Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      snapshot.data!,
                      errorBuilder: (_, error, stack) =>
                          const Text('Image unavailable.'),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              snapshot.data!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
              errorBuilder: (_, error, stack) => _failure(),
            ),
          ),
        );
      },
    ),
  );
}
