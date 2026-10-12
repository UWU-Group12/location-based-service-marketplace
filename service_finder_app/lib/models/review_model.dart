import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String requestId;
  final String customerId;
  final String providerId;
  final double rating;
  final String? comment;
  final String moderationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    required this.reviewId,
    required this.requestId,
    required this.customerId,
    required this.providerId,
    required this.rating,
    this.comment,
    required this.moderationStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();

    return ReviewModel(
      reviewId: snapshot.id,
      requestId: data?['requestId'] ?? '',
      customerId: data?['customerId'] ?? '',
      providerId: data?['providerId'] ?? '',
      rating: (data?['rating'] as num?)?.toDouble() ?? 0,
      comment: data?['comment'] as String?,
      moderationStatus: data?['moderationStatus'] ?? 'visible',
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data?['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
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
