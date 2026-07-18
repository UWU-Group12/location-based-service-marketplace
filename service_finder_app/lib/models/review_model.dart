import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel{
  final String requestId;
  final String customerId;
  final String providerId;
  final double rating;
  final String? comment;
  final String moderationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;


  ReviewModel({
    required this.requestId,
    required this.customerId,
    required this.providerId,
    required this.rating,
    this.comment,
    required this.moderationStatus,
    required this.createdAt,
    required this.updatedAt,
});
  factory ReviewModel.fromFirebase(String docId, Map<String, dynamic>data){
    return ReviewModel(
      requestId: docId,
      customerId: data['customerId']?? '',
      providerId: data['providerId']?? '',
      rating: (data['rating']?? 0.0).toDouble(),
      comment: data['comment'],
      moderationStatus: data['moderationStatus']?? 'visible',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt']as Timestamp).toDate(),
    );
  }
  Map<String,dynamic>toFirestore(){
    return{
     'requestId': requestId,
      'customerId': customerId,
      'providerId': providerId,
      'rating': rating,
      'comment': comment,
      'moderationStatus': moderationStatus,
      'createdAt': Timestamp.fromDate(createdAt),
     'updatedAt': Timestamp.fromDate(updatedAt),

    };
  }
}
