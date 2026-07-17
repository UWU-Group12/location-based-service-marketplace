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

  factory ServiceCategory.fromFireBase(DocumentSnapshot<Map<String, dynamic>> document){

    final data = document.data();

    if(data == null){
      throw StateError("Category ID ${document.id} dosen't contain data");
    }

    final String iconPath = data['iconPath'] as String;

    return ServiceCategory(
        id: document.id,
        name: data['name'] as String,
        description: data['description'] as String,
        iconPath: iconPath,
        active: data['active'] as bool,
        sortOrder: (data['sortOrder'] as num).toInt());
  }
}