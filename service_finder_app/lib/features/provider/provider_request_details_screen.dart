import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../models/quotation_model.dart';
import '../../models/service_request_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/profile_settings.dart';
import '../../widgets/request_widgets.dart';

class ProviderRequestDetailsScreen extends StatefulWidget {
  final String requestId;
  final String? quotationId;
  final bool isJob;

  const ProviderRequestDetailsScreen({
    super.key,
    required this.requestId,
    this.quotationId,
    this.isJob = false,
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
  String? _watchedQuotationId;
  bool _startingJob = false;

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
    _watchedQuotationId = widget.requestId;
  }

  Future<void> _startJob(ServiceRequestModel request) async {
    if (_startingJob) return;
    setState(() => _startingJob = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start this job?'),
          content: const Text('The customer will see this job as in progress.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Start job'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      await _service.startJob(request.requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job started successfully.')),
      );
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
    } catch (error) {
      debugPrint('Unable to start job: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to start job. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _startingJob = false);
    }
  }

  Future<void> _createQuotation(ServiceRequestModel request) async {
    final sent = await AppRouter.goToCreateQuotation(context, request);
    if (!mounted || !sent) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      centerTitle: true,
      title: Text(
        widget.isJob
            ? 'Job details'
            : widget.quotationId == null
            ? 'Request details'
            : 'Sent quotation',
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
              if (widget.isJob &&
                  !request.isActiveJob &&
                  !request.isFinishedJob) {
                return const RequestStateView(
                  title: 'Job no longer active',
                  message:
                      'This request is no longer an active or completed job.',
                  icon: Icons.work_off_outlined,
                );
              }
              final quotationId = widget.isJob
                  ? request.acceptedQuotationId ?? request.requestId
                  : request.requestId;
              if (_watchedQuotationId != quotationId) {
                _watchedQuotationId = quotationId;
                _quotation = _service.watchQuotation(quotationId);
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
                  final customerName =
                      request.customerName?.trim().isNotEmpty ?? false
                      ? request.customerName!.trim()
                      : 'Name unavailable';
                  final preferredVisit = [
                    if (request.preferredDate != null)
                      requestDateLabel(context, request.preferredDate),
                    if (request.preferredTime?.trim().isNotEmpty ?? false)
                      request.preferredTime!.trim(),
                  ].join(' · ');
                  final images = request.imagePaths ?? const <String>[];
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      ProfileSettingsGroup(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.all(18),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.08,
                              ),
                              child: const Icon(
                                Icons.person_outline,
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
                                '$customerName\n${requestStatusLabel(request.requestStatus)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.isJob)
                        RequestSection('Job', [
                          ProfileSettingsRow(
                            icon: Icons.work_outline,
                            title: 'Status',
                            value: request.isFinishedJob
                                ? 'Completed and kept in your history.'
                                : request.requestStatus == 'in_progress'
                                ? 'In progress. Moves to Finished when the customer marks it completed.'
                                : 'Customer accepted your quotation. Start the job when work begins.',
                          ),
                          if (request.requestStatus == 'confirmed' &&
                              quote?.status == 'accepted')
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _startingJob
                                      ? null
                                      : () => _startJob(request),
                                  icon: _startingJob
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.play_arrow),
                                  label: Text(
                                    _startingJob ? 'Starting...' : 'Start job',
                                  ),
                                ),
                              ),
                            ),
                        ]),
                      RequestSection('Request', [
                        ProfileSettingsRow(
                          icon: Icons.description_outlined,
                          title: 'Customer problem',
                          value: request.description.trim().isEmpty
                              ? 'Not provided'
                              : request.description.trim(),
                        ),
                        ProfileSettingsRow(
                          icon: Icons.category_outlined,
                          title: 'Service category',
                          value: requestStatusLabel(request.categoryId),
                        ),
                        ProfileSettingsRow(
                          icon: Icons.event_outlined,
                          title: 'Preferred visit',
                          value: preferredVisit.isEmpty
                              ? 'Not provided'
                              : preferredVisit,
                        ),
                        if (request.finalAmount != null)
                          ProfileSettingsRow(
                            icon: Icons.payments_outlined,
                            title: 'Final amount',
                            value:
                                'Rs. ${request.finalAmount!.toStringAsFixed(2)}',
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
                      if (images.isNotEmpty)
                        RequestSection('Photos', [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                            child: Column(
                              children: images
                                  .map(
                                    (path) => _RequestImage(
                                      key: ValueKey(path),
                                      path: path,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ]),
                      if (quote != null)
                        RequestSection(
                          widget.isJob
                              ? 'Accepted quotation'
                              : 'Your quotation',
                          [
                            ProfileSettingsRow(
                              icon: Icons.verified_outlined,
                              title: 'Status',
                              value: quote.status == 'sent'
                                  ? (request.isAwaitingQuotationApproval
                                        ? 'Waiting for customer approval'
                                        : 'Sent - request ${requestStatusLabel(request.requestStatus).toLowerCase()}')
                                  : requestStatusLabel(quote.status),
                            ),
                            ProfileSettingsRow(
                              icon: Icons.payments_outlined,
                              title:
                                  'Estimated total: Rs. ${quote.estimatedTotal.toStringAsFixed(2)}',
                              value: quote.inspectionFee == null
                                  ? 'Service charge Rs. ${quote.serviceCharge.toStringAsFixed(2)}'
                                  : 'Service charge Rs. ${quote.serviceCharge.toStringAsFixed(2)} · Inspection fee Rs. ${quote.inspectionFee!.toStringAsFixed(2)}',
                            ),
                            if (quote.materialCostNote?.trim().isNotEmpty ??
                                false)
                              ProfileSettingsRow(
                                icon: Icons.build_outlined,
                                title: 'Material costs',
                                value: quote.materialCostNote!.trim(),
                              ),
                            if (quote.availableAt != null)
                              ProfileSettingsRow(
                                icon: Icons.schedule_outlined,
                                title: 'Available visit',
                                value: requestDateTimeLabel(
                                  context,
                                  quote.availableAt,
                                ),
                              ),
                            if (quote.message?.trim().isNotEmpty ?? false)
                              ProfileSettingsRow(
                                icon: Icons.chat_bubble_outline,
                                title: 'Message to customer',
                                value: quote.message!.trim(),
                              ),
                            if (!widget.isJob && quote.expiresAt != null)
                              ProfileSettingsRow(
                                icon: Icons.timer_outlined,
                                title: 'Expires on',
                                value: requestDateTimeLabel(
                                  context,
                                  quote.expiresAt,
                                ),
                              ),
                          ],
                        ),
                      if ((widget.isJob || widget.quotationId != null) &&
                          quote == null)
                        RequestSection('Quotation', const [
                          ProfileSettingsRow(
                            icon: Icons.error_outline,
                            title: 'Quotation unavailable',
                            value: 'This quotation is no longer available.',
                          ),
                        ]),
                      if (!widget.isJob &&
                          request.canReceiveQuotation &&
                          !hasSentQuote &&
                          widget.quotationId == null) ...[
                        const SizedBox(height: 30),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () => _createQuotation(request),
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: const Text('Create quotation'),
                          ),
                        ),
                      ],
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
