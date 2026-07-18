
import 'package:cloud_firestore/cloud_firestore.dart';

class QuotationModel{
  final String quotationId; //quotation id
  final String requestId; //service request id
  final String customerId;
  final String providerId;
  final double serviceCharge; //
  final double? inspectionFee;
  final String? materialCostNote; //
  final double estimatedTotal;
  final DateTime? availableAt; // provider available time
  final String? message; //message to customer from provider
  final String status; //accepted rejected or expired
  final DateTime? expiresAt; //quotation expire time
  final DateTime createdAt; //quotation creating time
  final DateTime updatedAt; //last modification time


  QuotationModel({
    required this.quotationId,
    required this.requestId,
    required this.customerId,
    required this.providerId,
    required this.serviceCharge,
    this.inspectionFee,
    this.materialCostNote,
    required this.estimatedTotal,
    this.availableAt,
    this.message,
    required this.status,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    });

  factory QuotationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot){
      final data = snapshot.data();
      return QuotationModel(
        quotationId: snapshot.id,
        requestId: data?['requestId'] ?? '', //? Only try to get requestId if data exists
        customerId: data?['customerId'] ?? '',
        providerId: data?['providerId'] ?? '',
        serviceCharge: (data?['serviceCharge']?? 0.0).toDouble(),
        inspectionFee: data?['inspectionFee'] !=null? (data?['inspectionFee']as num).toDouble():null,//ternary operator
        materialCostNote: data?['materialCostNote'],
        estimatedTotal: (data?['estimatedTotal'] ?? 0.0).toDouble(),
        availableAt: data?['availableAt'] != null? (data?['availableAt'] as Timestamp).toDate() : null,
        message: data?['message'],
        status: data?['status'] ?? 'sent', //this means the quotation is sent to the provider
        expiresAt: data?['expiresAt'] != null? (data?['expiresAt'] as Timestamp).toDate() : null,
        createdAt: (data?['createdAt'] as Timestamp).toDate(),
        updatedAt: (data?['updatedAt'] as Timestamp).toDate(),
      );
}

Map<String, dynamic> toFirestore(){
    return{
      'requestId': requestId,
      'customerId': customerId,
      'providerId': providerId,
      'serviceCharge': serviceCharge,
      'inspectionFee': inspectionFee,
      'materialCostNote': materialCostNote,
      'estimatedTotal': estimatedTotal,
      'availableAt': availableAt !=null? Timestamp.fromDate(availableAt!): null, //! inside the brackeets means i know this isnt null
      'message': message,
      'status': status,
      'expiresAt': expiresAt !=null ? Timestamp.fromDate(expiresAt!):null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),


    };
}
}

