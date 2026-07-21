import 'package:cloud_firestore/cloud_firestore.dart';

class SupportedLocation {
  final String id;
  final String name;
  final String district;
  final String province;

  const SupportedLocation({
    required this.id,
    required this.name,
    required this.district,
    required this.province,
  });

  factory SupportedLocation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    return SupportedLocation(
      id: document.id,
      name: data['name'] as String? ?? '',
      district: data['district'] as String? ?? '',
      province: data['province'] as String? ?? '',
    );
  }
}
