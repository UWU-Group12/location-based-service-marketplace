import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/provider_model.dart';
import '../models/quotation_model.dart';
import '../models/service_category_model.dart';
import '../models/service_request_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<ServiceRequestModel?> watchCustomerRequest(String requestId) {
    final customerId = FirebaseAuth.instance.currentUser?.uid;
    if (customerId == null) return const Stream<ServiceRequestModel?>.empty();

    return _firestore
        .collection('serviceRequests')
        .doc(requestId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (data == null || data['customerId'] != customerId) return null;
          return ServiceRequestModel.fromFirestore(doc.id, data);
        });
  }

  Stream<ServiceRequestModel?> watchProviderRequest(
    String requestId,
    String providerId,
  ) {
    return _firestore
        .collection('serviceRequests')
        .doc(requestId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (data == null || data['providerId'] != providerId) return null;
          return ServiceRequestModel.fromFirestore(doc.id, data);
        });
  }

  Stream<List<QuotationModel>> watchProviderQuotations(String providerId) {
    return _firestore
        .collection('quotations')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
          final quotations = snapshot.docs
              .map(QuotationModel.fromFirestore)
              .toList();
          quotations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return quotations;
        });
  }

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

  Stream<List<ProviderModel>> watchTopRatedAvailableProviders({int limit = 4}) {
    return _firestore
        .collection('providerProfiles')
        .where('verificationStatus', isEqualTo: 'verified')
        .where('availabilityStatus', isEqualTo: 'available')
        .orderBy('ratingAverage', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) =>
                    ProviderModel.fromFirestore(document.id, document.data()),
              )
              .toList(growable: false),
        );
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

  Stream<ProviderModel?> watchProviderProfile(String providerId) {
    return _firestore
        .collection('providerProfiles')
        .doc(providerId)
        .snapshots()
        .map((document) {
          final data = document.data();
          return data == null
              ? null
              : ProviderModel.fromFirestore(document.id, data);
        });
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
    required GeoPoint baseLocation,
    required double serviceRadiusKm,
    String? profileImagePath,
  }) async {
    if (![5.0, 10.0, 15.0, 20.0, 30.0].contains(serviceRadiusKm)) {
      throw ArgumentError('Select a supported service radius.');
    }
    final providerReference = _firestore
        .collection('providerProfiles')
        .doc(providerId);
    final userReference = _firestore.collection('users').doc(providerId);

    final batch = _firestore.batch();
    batch.update(providerReference, {
      'displayName': displayName.trim(),
      'bio': bio.trim(),
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != request.customerId) {
      throw StateError('Please sign in before creating a service request.');
    }
    // Save the name with the request; providers cannot read private user profiles.
    final customer = await _firestore.collection('users').doc(user.uid).get();
    final profileName = (customer.data()?['displayName'] as String?)?.trim();
    final customerName = profileName != null && profileName.isNotEmpty
        ? profileName
        : user.displayName?.trim();
    if (customerName == null || customerName.isEmpty) {
      throw StateError(
        'Please add your name to your profile before requesting a service.',
      );
    }
    final requestReference = _firestore.collection('serviceRequests').doc();
    final requestData = request.toFirestore();

    requestData['customerName'] = customerName;
    requestData['createdAt'] = FieldValue.serverTimestamp();
    requestData['updatedAt'] = FieldValue.serverTimestamp();

    await requestReference.set(requestData);
    return requestReference.id;
  }

  Stream<List<ServiceRequestModel>> watchCustomerRequests(String customerId) {
    return _firestore
        .collection('serviceRequests')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map(
                (doc) => ServiceRequestModel.fromFirestore(doc.id, doc.data()),
              )
              .toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  /// The quotation document ID is the request ID (one quotation per request).
  Stream<QuotationModel?> watchQuotation(String requestId) {
    return _firestore
        .collection('quotations')
        .doc(requestId)
        .snapshots()
        .map((doc) => doc.exists ? QuotationModel.fromFirestore(doc) : null);
  }

  Future<void> sendQuotation(QuotationModel quotation) async {
    final providerId = FirebaseAuth.instance.currentUser?.uid;
    if (providerId == null || providerId != quotation.providerId) {
      throw StateError('Please sign in as the assigned provider.');
    }
    final inspectionFee = quotation.inspectionFee ?? 0;
    if (!quotation.serviceCharge.isFinite ||
        quotation.serviceCharge <= 0 ||
        !inspectionFee.isFinite ||
        inspectionFee < 0 ||
        !quotation.estimatedTotal.isFinite ||
        (quotation.estimatedTotal - (quotation.serviceCharge + inspectionFee))
                .abs() >
            0.001) {
      throw StateError('Enter valid service and inspection charges.');
    }
    if (quotation.availableAt != null &&
        !quotation.availableAt!.isAfter(DateTime.now())) {
      throw StateError('Please choose a future available date and time.');
    }
    final quotationData = quotation.toFirestore();
    quotationData['status'] = 'sent';
    quotationData['createdAt'] = FieldValue.serverTimestamp();
    quotationData['updatedAt'] = FieldValue.serverTimestamp();

    final requestRef = _firestore
        .collection('serviceRequests')
        .doc(quotation.requestId);
    final quotationRef = _firestore
        .collection('quotations')
        .doc(quotation.requestId);
    // Re-read both documents so a stale screen cannot overwrite a sent or
    // accepted quotation or reopen a cancelled request.
    await _firestore.runTransaction((transaction) async {
      final requestDoc = await transaction.get(requestRef);
      final quotationDoc = await transaction.get(quotationRef);
      final requestData = requestDoc.data();
      if (requestData == null) {
        throw StateError('This request is no longer available.');
      }
      final request = ServiceRequestModel.fromFirestore(
        requestDoc.id,
        requestData,
      );
      final existingStatus = quotationDoc.data()?['status'];
      if (request.providerId != providerId ||
          request.customerId != quotation.customerId ||
          !request.canReceiveQuotation ||
          (quotationDoc.exists &&
              existingStatus != 'rejected' &&
              existingStatus != 'expired')) {
        throw StateError(
          'This request has changed or already has a quotation. Return to Request to view its latest status.',
        );
      }
      transaction.set(quotationRef, quotationData);
      transaction.update(requestRef, {
        'requestStatus': 'quotation_received',
        'quotationStatus': 'sent',
        // The provider is the one who sets the price. Recording it here means
        // the customer can accept or reject it but never write it.
        'finalAmount': quotation.estimatedTotal,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> acceptQuotation(QuotationModel quotation) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('quotations').doc(quotation.requestId), {
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(
      _firestore.collection('serviceRequests').doc(quotation.requestId),
      {
        'requestStatus': 'confirmed',
        'quotationStatus': 'accepted',
        'acceptedQuotationId': quotation.requestId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
  }

  Future<void> rejectQuotation(String requestId) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('quotations').doc(requestId), {
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection('serviceRequests').doc(requestId), {
      'requestStatus': 'cancelled',
      'quotationStatus': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> rejectRequest(String requestId) =>
      _updateRequestStatus(requestId, 'provider_rejected');

  Future<void> cancelRequest(String requestId) =>
      _updateRequestStatus(requestId, 'cancelled');

  Future<void> startJob(String requestId) async {
    final providerId = FirebaseAuth.instance.currentUser?.uid;
    if (providerId == null) {
      throw StateError('Please sign in to start this job.');
    }
    final reference = _firestore.collection('serviceRequests').doc(requestId);
    await _firestore.runTransaction((transaction) async {
      final document = await transaction.get(reference);
      final data = document.data();
      if (data == null) throw StateError('This job is no longer available.');
      final job = ServiceRequestModel.fromFirestore(document.id, data);
      if (job.providerId != providerId ||
          !job.isActiveJob ||
          job.requestStatus != 'confirmed') {
        throw StateError(
          'This job has changed. Only a confirmed job assigned to you can be started.',
        );
      }
      final quotation = await transaction.get(
        _firestore
            .collection('quotations')
            .doc(job.acceptedQuotationId ?? requestId),
      );
      final quotationData = quotation.data();
      if (quotationData == null ||
          quotationData['status'] != 'accepted' ||
          quotationData['requestId'] != requestId ||
          quotationData['providerId'] != providerId ||
          quotationData['customerId'] != job.customerId) {
        throw StateError(
          'The accepted quotation is unavailable. Please reload this job.',
        );
      }
      transaction.update(reference, {
        'requestStatus': 'in_progress',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> confirmJobDone(String requestId) async {
    final customerId = FirebaseAuth.instance.currentUser?.uid;
    if (customerId == null) {
      throw StateError('Please sign in to confirm this job is done.');
    }
    final reference = _firestore.collection('serviceRequests').doc(requestId);
    await _firestore.runTransaction((transaction) async {
      final document = await transaction.get(reference);
      final data = document.data();
      if (data == null) {
        throw StateError('This request is no longer available.');
      }
      final request = ServiceRequestModel.fromFirestore(document.id, data);
      if (request.customerId != customerId ||
          request.requestStatus != 'in_progress') {
        throw StateError(
          'This job has changed. Only a job in progress that you booked can be confirmed as done.',
        );
      }
      transaction.update(reference, {
        'requestStatus': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _updateRequestStatus(String requestId, String status) {
    return _firestore.collection('serviceRequests').doc(requestId).update({
      'requestStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
