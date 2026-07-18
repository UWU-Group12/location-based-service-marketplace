import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/provider_model.dart';
import '../models/service_category_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ServiceCategory>> getActiveCategories() async {
    final categoriesCollection = _firestore.collection("categories");

    final query = categoriesCollection
        .where('active', isEqualTo: true)
        .orderBy('sortOrder');

    final querySnapshot = await query.get();

    final List<ServiceCategory> categories = [];

    for (final document in querySnapshot.docs) {
      final ServiceCategory category = ServiceCategory.fromFireBase(document);
      categories.add(category);
    }

    return categories;
  }

  Future<void> createProviderProfile(
    ProviderModel provider, {
    String? phoneNumber,
  }) async {
    final providerReference = _firestore
        .collection('providerProfiles')
        .doc(provider.providerId);
    final userReference = _firestore
        .collection('users')
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
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
        'phoneNumber': phoneNumber.trim(),
    };

    final batch = _firestore.batch();
    batch.set(providerReference, providerData);
    batch.update(userReference, userUpdates);
    await batch.commit();
  }
}
