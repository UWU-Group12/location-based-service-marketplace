import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRequestModel {
  final String requestId;
  final String customerId;
  final String providerId;
  final String categoryId;
  final String title;
  final String description;
  final List<String>? imagePaths;

  final GeoPoint servicePoint;
  final String serviceGeohash; //when the GeoPoint gives the coordinates this convert it into a encrypted location code
  final String addressText; //human readable version of the address

  final String requestStatus; // 'submitted', 'provider_rejected', 'quotation_received', etc.
  final String quotationStatus; // 'pending', 'sent', 'accepted', etc.
  final String? acceptedQuotationId;
  final double? finalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceRequestModel({
    required this.requestId,
    required this.customerId,
    required this.providerId,
    required this.categoryId,
    required this.title,
    required this.description,
    this.imagePaths,
    required this.servicePoint,
    required this.serviceGeohash,
    required this.addressText,
    required this.requestStatus,
    required this.quotationStatus,
    this.acceptedQuotationId,
    this.finalAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceRequestModel.fromFirestore(String docId ,Map<String , dynamic> data){
    final locationData = data['serviceLocation']as Map<String, dynamic>? ?? {};
        return ServiceRequestModel(
          requestId: docId,
          customerId: data['customerId'] ?? '',
          providerId: data['providerId'] ?? '',
          categoryId: data['categoryId'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          imagePaths: data['imagePaths'] !=null? List<String>.from(data['imagePaths']): null,
          servicePoint: locationData['point'] as GeoPoint? ?? const GeoPoint(0, 0),
          serviceGeohash: locationData['geohash'] ?? '',
          addressText: locationData['addressText'] ?? '',
          requestStatus: data['requestStatus'] ?? 'submitted',
          quotationStatus: data['quotationStatus'] ?? 'pending',
          acceptedQuotationId: data['acceptedQuotationId'],
          finalAmount: data['finalAmount'] != null ? (data['finalAmount'] as num).toDouble() : null,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
  );
  }
  Map <String ,dynamic> toFirestore(){
    return{
      'customerId': customerId,
      'providerId': providerId,
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'imagePaths': imagePaths,
      'serviceLocation': {'point': servicePoint,'geohash': serviceGeohash,'addressText': addressText,},
      'requestStatus': requestStatus,
      'quotationStatus': quotationStatus,
      'acceptedQuotationId': acceptedQuotationId,
      'finalAmount': finalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
  };
  }
}