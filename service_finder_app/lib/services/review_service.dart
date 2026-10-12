import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review_model.dart';
import '../models/service_request_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<ServiceRequestModel?> getRequestById(String requestId) async {
    final snapshot = await _firestore
        .collection('serviceRequests')
        .doc(requestId)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return ServiceRequestModel.fromFirestore(snapshot.id, snapshot.data()!);
  }

  Future<String> submitReview({
    required String requestId,
    required String customerId,
    required String providerId,
    required double rating,
    String? comment,
  }) async {
    final reference = _firestore.collection('reviews').doc(requestId);

    await reference.set({
      'requestId': requestId,
      'customerId': customerId,
      'providerId': providerId,
      'rating': rating,
      'comment': comment?.trim().isEmpty ?? true ? null : comment!.trim(),
      'moderationStatus': 'visible',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return reference.id;
  }

  Future<bool> hasReviewed(String requestId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .doc(requestId)
        .get();
    return snapshot.exists;
  }

  Stream<Set<String>> watchReviewedRequestIds(String customerId) {
    return _firestore
        .collection('reviews')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((document) => document.id).toSet(),
        );
  }

  Stream<ReviewModel?> watchReview(String requestId) {
    return _firestore
        .collection('reviews')
        .doc(requestId)
        .snapshots()
        .map(
          (snapshot) => snapshot.data() == null
              ? null
              : ReviewModel.fromFirestore(snapshot),
        );
  }

  Stream<List<ReviewModel>> watchProviderReviews(String providerId) {
    return _firestore
        .collection('reviews')
        .where('providerId', isEqualTo: providerId)
        .where('moderationStatus', isEqualTo: 'visible')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ReviewModel.fromFirestore)
              .toList(growable: false),
        );
  }
}
