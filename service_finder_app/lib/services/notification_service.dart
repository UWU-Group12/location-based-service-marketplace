import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quotation_model.dart';
import '../models/review_model.dart';
import '../models/service_request_model.dart';
import 'firestore_service.dart';
import 'review_service.dart';

enum ProviderNotificationType {
  receivedRequest,
  sentRequest,
  activeJob,
  finishedJob,
  rating,
  system,
}

class ProviderNotificationItem {
  final String id;
  final ProviderNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? requestId;
  final String? quotationId;
  final String? reviewId;
  final bool unread;

  const ProviderNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.requestId,
    this.quotationId,
    this.reviewId,
    this.unread = false,
  });
}

class NotificationService {
  final FirebaseFirestore _firestore;
  final FirestoreService _requests;
  final ReviewService _reviews;

  NotificationService({
    FirebaseFirestore? firestore,
    FirestoreService? requests,
    ReviewService? reviews,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _requests = requests ?? FirestoreService(firestore: firestore),
       _reviews = reviews ?? ReviewService();

  Stream<List<ProviderNotificationItem>> watchProviderNotifications(
    String providerId,
  ) {
    late StreamSubscription<List<ServiceRequestModel>> requestSubscription;
    late StreamSubscription<List<QuotationModel>> quotationSubscription;
    late StreamSubscription<List<ReviewModel>> reviewSubscription;
    late StreamSubscription<List<ProviderNotificationItem>> systemSubscription;

    final controller = StreamController<List<ProviderNotificationItem>>();
    var requests = <ServiceRequestModel>[];
    var quotations = <QuotationModel>[];
    var reviews = <ReviewModel>[];
    var system = <ProviderNotificationItem>[];

    Future<void> emit() async {
      if (controller.isClosed) return;
      final readIds = await _readNotificationIds(providerId);
      final items =
          <ProviderNotificationItem>[
                ..._requestNotifications(requests, quotations),
                ..._ratingNotifications(reviews),
                ...system,
              ]
              .map(
                (item) => ProviderNotificationItem(
                  id: item.id,
                  type: item.type,
                  title: item.title,
                  message: item.message,
                  createdAt: item.createdAt,
                  requestId: item.requestId,
                  quotationId: item.quotationId,
                  reviewId: item.reviewId,
                  unread: item.unread && !readIds.contains(item.id),
                ),
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(List.unmodifiable(items));
    }

    controller.onListen = () {
      requestSubscription = _requests.watchProviderRequests(providerId).listen((
        value,
      ) {
        requests = value;
        emit();
      }, onError: controller.addError);
      quotationSubscription = _requests
          .watchProviderQuotations(providerId)
          .listen((value) {
            quotations = value;
            emit();
          }, onError: controller.addError);
      reviewSubscription = _reviews.watchProviderReviews(providerId).listen((
        value,
      ) {
        reviews = value;
        emit();
      }, onError: controller.addError);
      systemSubscription = watchProviderSystemNotifications(providerId).listen(
        (value) {
          system = value;
          emit();
        },
        onError: (_) {
          system = const [];
          emit();
        },
      );
    };

    controller.onCancel = () async {
      await requestSubscription.cancel();
      await quotationSubscription.cancel();
      await reviewSubscription.cancel();
      await systemSubscription.cancel();
    };

    return controller.stream;
  }

  Future<void> markProviderNotificationsRead(
    String providerId,
    Iterable<ProviderNotificationItem> notifications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _readKey(providerId);
    final ids = prefs.getStringList(key)?.toSet() ?? <String>{};
    ids.addAll(notifications.map((notification) => notification.id));
    await prefs.setStringList(key, ids.toList()..sort());
  }

  Future<Set<String>> _readNotificationIds(String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_readKey(providerId)) ?? const <String>[])
        .toSet();
  }

  String _readKey(String providerId) =>
      'provider_read_notifications_$providerId';

  Stream<List<ProviderNotificationItem>> watchProviderSystemNotifications(
    String providerId,
  ) {
    return _firestore
        .collection('notifications')
        .where('targetRole', whereIn: ['provider', 'all'])
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                final data = doc.data();
                final targetProvider = data['providerId'] as String?;
                return targetProvider == null ||
                    targetProvider.isEmpty ||
                    targetProvider == providerId;
              })
              .map(_systemNotificationFromDocument)
              .toList(growable: false),
        );
  }

  List<ProviderNotificationItem> _requestNotifications(
    List<ServiceRequestModel> requests,
    List<QuotationModel> quotations,
  ) {
    final requestById = {
      for (final request in requests) request.requestId: request,
    };
    final sentQuotationIds = quotations
        .where((quote) => quote.status == 'sent')
        .map((quote) => quote.requestId)
        .toSet();

    final items = <ProviderNotificationItem>[];
    for (final request in requests) {
      if (request.canReceiveQuotation &&
          !sentQuotationIds.contains(request.requestId)) {
        items.add(
          ProviderNotificationItem(
            id: 'received-${request.requestId}',
            type: ProviderNotificationType.receivedRequest,
            title: 'New request received',
            message: _requestMessage(request),
            createdAt: request.createdAt,
            requestId: request.requestId,
            unread: true,
          ),
        );
      }
      if (request.isActiveJob) {
        items.add(
          ProviderNotificationItem(
            id: 'active-${request.requestId}',
            type: ProviderNotificationType.activeJob,
            title: request.requestStatus == 'in_progress'
                ? 'Job in progress'
                : 'Active job confirmed',
            message: _requestMessage(request),
            createdAt: request.updatedAt,
            requestId: request.requestId,
          ),
        );
      }
      if (request.isFinishedJob) {
        items.add(
          ProviderNotificationItem(
            id: 'finished-${request.requestId}',
            type: ProviderNotificationType.finishedJob,
            title: 'Job finished',
            message: _requestMessage(request),
            createdAt: request.updatedAt,
            requestId: request.requestId,
          ),
        );
      }
    }

    for (final quotation in quotations.where(
      (quote) => quote.status == 'sent',
    )) {
      final request = requestById[quotation.requestId];
      items.add(
        ProviderNotificationItem(
          id: 'sent-${quotation.quotationId}',
          type: ProviderNotificationType.sentRequest,
          title: 'Quotation sent',
          message: request == null
              ? 'Your quotation is waiting for customer approval.'
              : '${request.title} is waiting for customer approval.',
          createdAt: quotation.updatedAt,
          requestId: quotation.requestId,
          quotationId: quotation.quotationId,
          unread: true,
        ),
      );
    }

    return items;
  }

  List<ProviderNotificationItem> _ratingNotifications(
    List<ReviewModel> reviews,
  ) {
    return reviews
        .map(
          (review) => ProviderNotificationItem(
            id: 'rating-${review.reviewId}',
            type: ProviderNotificationType.rating,
            title: 'New rating received',
            message: review.comment == null || review.comment!.trim().isEmpty
                ? 'You received ${review.rating.toStringAsFixed(1)} stars.'
                : 'You received ${review.rating.toStringAsFixed(1)} stars: ${review.comment!.trim()}',
            createdAt: review.createdAt,
            requestId: review.requestId,
            reviewId: review.reviewId,
            unread: true,
          ),
        )
        .toList(growable: false);
  }

  ProviderNotificationItem _systemNotificationFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ??
        (data['updatedAt'] as Timestamp?)?.toDate() ??
        DateTime.now();
    return ProviderNotificationItem(
      id: 'system-${document.id}',
      type: ProviderNotificationType.system,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : 'System notification',
      message: (data['message'] as String?)?.trim().isNotEmpty == true
          ? (data['message'] as String).trim()
          : 'Open to view this notification.',
      createdAt: createdAt,
      requestId: data['requestId'] as String?,
      unread: data['read'] != true,
    );
  }

  String _requestMessage(ServiceRequestModel request) {
    final customer =
        request.customerName == null || request.customerName!.isEmpty
        ? 'Customer'
        : request.customerName!;
    return '$customer · ${request.title}';
  }
}
