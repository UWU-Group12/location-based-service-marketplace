import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final bool active;
  final int sortOrder;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.active,
    required this.sortOrder,
  });

  factory ServiceCategory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final categoryId = document.id;

    if (data == null) {
      throw StateError('Category $categoryId does not contain data.');
    }

    final name = data['name'];
    if (name is! String || name.trim().isEmpty) {
      throw FormatException('Category $categoryId has no valid name.');
    }

    return ServiceCategory(
      id: categoryId,
      name: name.trim(),
      description: _optionalString(data['description']),
      iconPath: _optionalString(data['iconPath']),
      active: data['active'] as bool? ?? false,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  static String _optionalString(dynamic value) {
    return value is String ? value.trim() : '';
  }
}
