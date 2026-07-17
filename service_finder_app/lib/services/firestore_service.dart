import 'package:cloud_firestore/cloud_firestore.dart';

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
}
