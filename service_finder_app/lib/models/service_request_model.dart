import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRequestModel {
  final String requestId;
  final String customerId;
  final String? customerName;
  final String providerId;
  final String categoryId;
  final String title;
  final String description;
  final List<String>? imagePaths;
  final GeoPoint servicePoint;
  final String addressText;
  final String requestStatus;
  final String quotationStatus;
  final String? acceptedQuotationId;
  final double? finalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? preferredDate;
  final String? preferredTime;

  bool get isActiveJob =>
      quotationStatus == 'accepted' &&
      (requestStatus == 'confirmed' || requestStatus == 'in_progress');

  bool get isFinishedJob => requestStatus == 'completed';

  bool get isAwaitingQuotationApproval =>
      requestStatus == 'quotation_received' && quotationStatus == 'sent';

  bool get canReceiveQuotation =>
      requestStatus == 'submitted' &&
      (quotationStatus == 'pending' ||
          quotationStatus == 'rejected' ||
          quotationStatus == 'expired');

  ServiceRequestModel({
    required this.requestId,
    required this.customerId,
    this.customerName,
    required this.providerId,
    required this.categoryId,
    required this.title,
    required this.description,
    this.imagePaths,
    required this.servicePoint,
    required this.addressText,
    required this.requestStatus,
    required this.quotationStatus,
    this.acceptedQuotationId,
    this.finalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.preferredDate,
    this.preferredTime,
  });

  factory ServiceRequestModel.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    final locationData = data['serviceLocation'] as Map<String, dynamic>? ?? {};

    return ServiceRequestModel(
      requestId: docId,
      customerId: data['customerId'] as String? ?? '',
      customerName: (data['customerName'] as String?)?.trim(),
      providerId: data['providerId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imagePaths: data['imagePaths'] == null
          ? null
          : List<String>.from(data['imagePaths'] as List),
      servicePoint: locationData['point'] as GeoPoint? ?? const GeoPoint(0, 0),
      addressText: locationData['addressText'] as String? ?? '',
      requestStatus: data['requestStatus'] as String? ?? 'submitted',
      quotationStatus: data['quotationStatus'] as String? ?? 'pending',
      acceptedQuotationId: data['acceptedQuotationId'] as String?,
      finalAmount: (data['finalAmount'] as num?)?.toDouble(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      preferredDate: data['preferredDate'] is Timestamp
          ? (data['preferredDate'] as Timestamp).toDate()
          : DateTime.tryParse(data['preferredDate']?.toString() ?? ''),
      preferredTime: data['preferredTime'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      if (customerName != null && customerName!.trim().isNotEmpty)
        'customerName': customerName!.trim(),
      'providerId': providerId,
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'imagePaths': imagePaths,
      'serviceLocation': {'point': servicePoint, 'addressText': addressText},
      'requestStatus': requestStatus,
      'quotationStatus': quotationStatus,
      'acceptedQuotationId': acceptedQuotationId,
      'finalAmount': finalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
