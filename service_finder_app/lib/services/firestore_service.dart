import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/provider_model.dart';
import '../models/service_category_model.dart';
import '../models/service_request_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ServiceRequestModel>> watchProviderRequests(String providerId) {
    return _firestore
        .collection('serviceRequests')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map(
                (doc) => ServiceRequestModel.fromFirestore(doc.id, doc.data()),
              )
              .toList();
          requests.sort((a, b) {
            final comparison = b.createdAt.compareTo(a.createdAt);
            return comparison != 0
                ? comparison
                : a.requestId.compareTo(b.requestId);
          });
          return requests;
        });
  }

  Future<List<ServiceCategory>> getActiveCategories() async {
    final snapshot = await _firestore
        .collection('categories')
        .where('active', isEqualTo: true)
        .get();

    final categories = snapshot.docs
        .map(ServiceCategory.fromFirestore)
        .toList();

    categories.sort((first, second) {
      final sortOrderComparison = first.sortOrder.compareTo(second.sortOrder);
      return sortOrderComparison != 0
          ? sortOrderComparison
          : first.name.compareTo(second.name);
    });

    return List.unmodifiable(categories);
  }

  Future<List<ProviderModel>> getVerifiedAvailableProvidersByCategory(
    String categoryId,
  ) async {
    final snapshot = await _firestore
        .collection('providerProfiles')
        .where('verificationStatus', isEqualTo: 'verified')
        .where('availabilityStatus', isEqualTo: 'available')
        .where('categoryIds', arrayContains: categoryId.trim())
        .get();

    return snapshot.docs
        .map(
          (document) =>
              ProviderModel.fromFirestore(document.id, document.data()),
        )
        .toList(growable: false);
  }

  Future<void> saveProviderLocationFields({
    required String providerId,
    required GeoPoint baseLocation,
    required double serviceRadiusKm,
  }) async {
    await _firestore.collection('providerProfiles').doc(providerId).update({
      'baseLocation': baseLocation,
      'serviceRadiusKm': serviceRadiusKm,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createProviderProfile(
    ProviderModel provider, {
    required String phoneNumber,
    required String frontDocumentPath,
    required String backDocumentPath,
  }) async {
    final providerReference = _firestore
        .collection('providerProfiles')
        .doc(provider.providerId);
    final userReference = _firestore
        .collection('users')
        .doc(provider.providerId);
    final verificationReference = _firestore
        .collection('providerVerifications')
        .doc(provider.providerId);

    final existingProvider = await providerReference.get();
    if (existingProvider.exists) {
      throw StateError('A provider profile already exists for this account.');
    }

    final providerData = provider.toFirestore();
    providerData['createdAt'] = FieldValue.serverTimestamp();
    providerData['updatedAt'] = FieldValue.serverTimestamp();

    final userUpdates = <String, dynamic>{
      'displayName': provider.displayName,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'phoneNumber': phoneNumber.trim(),
      if (provider.profileImagePath != null)
        'photoPath': provider.profileImagePath,
    };
    final verificationData = <String, dynamic>{
      'providerId': provider.providerId,
      'documentType': 'national_id',
      'frontDocumentPath': frontDocumentPath,
      'backDocumentPath': backDocumentPath,
      'certificatePaths': <String>[],
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedBy': null,
      'reviewedAt': null,
      'rejectionReason': null,
    };

    final batch = _firestore.batch();
    batch.set(providerReference, providerData);
    batch.set(verificationReference, verificationData);
    batch.update(userReference, userUpdates);
    await batch.commit();
  }

  Future<ProviderModel?> getProviderProfile(String providerId) async {
    final document = await _firestore
        .collection('providerProfiles')
        .doc(providerId)
        .get();
    final data = document.data();

    return data == null ? null : ProviderModel.fromFirestore(document.id, data);
  }

  Future<void> updateCustomerProfile({
    required String userId,
    required String displayName,
    required String phoneNumber,
    String? photoPath,
    bool clearPhoto = false,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'displayName': displayName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'photoPath': ?(clearPhoto ? FieldValue.delete() : photoPath),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProviderProfile({
    required String providerId,
    required String displayName,
    required String phoneNumber,
    required String bio,
    required String categoryId,
    required GeoPoint baseLocation,
    required double serviceRadiusKm,
    String? profileImagePath,
  }) async {
    final providerReference = _firestore
        .collection('providerProfiles')
        .doc(providerId);
    final userReference = _firestore.collection('users').doc(providerId);

    final batch = _firestore.batch();
    batch.update(providerReference, {
      'displayName': displayName.trim(),
      'bio': bio.trim(),
      'categoryIds': [categoryId.trim()],
      'baseLocation': baseLocation,
      'serviceRadiusKm': serviceRadiusKm,
      'profileImagePath': ?profileImagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(userReference, {
      'displayName': displayName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'photoPath': ?profileImagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<String> createServiceRequest(ServiceRequestModel request) async {
    final requestReference = _firestore.collection('serviceRequests').doc();
    final requestData = request.toFirestore();

    requestData['createdAt'] = FieldValue.serverTimestamp();
    requestData['updatedAt'] = FieldValue.serverTimestamp();

    await requestReference.set(requestData);
    return requestReference.id;
  }
}
