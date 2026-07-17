import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedServiceCategories() async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  final categories = <String, Map<String, dynamic>>{
    'electrician': {
      'name': 'Electrician',
      'description': 'Electrical installation and repair services',
      'iconPath': 'categories/electrician_icon.png',
      'active': true,
      'sortOrder': 1,
    },
    'plumber': {
      'name': 'Plumber',
      'description': 'Plumbing installation and water leak repairs',
      'iconPath': 'categories/plumber_icon.png',
      'active': true,
      'sortOrder': 2,
    },
    'carpenter': {
      'name': 'Carpenter',
      'description': 'Furniture, doors, windows and woodwork services',
      'iconPath': 'categories/carpenter_icon.png',
      'active': true,
      'sortOrder': 3,
    },
    'mason': {
      'name': 'Mason',
      'description': 'Brickwork, concrete and building repair services',
      'iconPath': 'categories/mason_icon.png',
      'active': true,
      'sortOrder': 4,
    },
    'painter': {
      'name': 'Painter',
      'description': 'Interior and exterior painting services',
      'iconPath': 'categories/painter_icon.png',
      'active': true,
      'sortOrder': 5,
    },
    'welder': {
      'name': 'Welder',
      'description': 'Metal welding and fabrication services',
      'iconPath': 'categories/welder_icon.png',
      'active': true,
      'sortOrder': 6,
    },
    'tiler': {
      'name': 'Tiler',
      'description': 'Floor and wall tile installation services',
      'iconPath': 'categories/tiler_icon.png',
      'active': true,
      'sortOrder': 7,
    },
    'roofer': {
      'name': 'Roofer',
      'description': 'Roof installation and repair services',
      'iconPath': 'categories/roofer_icon.png',
      'active': true,
      'sortOrder': 8,
    },
    'air-conditioner-repair': {
      'name': 'Air Conditioner Repair',
      'description': 'Air conditioner installation and repair services',
      'iconPath': 'categories/air_conditioner_repair_icon.png',
      'active': true,
      'sortOrder': 9,
    },
    'refrigerator-repair': {
      'name': 'Refrigerator Repair',
      'description': 'Refrigerator diagnosis and repair services',
      'iconPath': 'categories/refrigerator_repair_icon.png',
      'active': true,
      'sortOrder': 10,
    },
    'washing-machine-repair': {
      'name': 'Washing Machine Repair',
      'description': 'Washing machine maintenance and repair services',
      'iconPath': 'categories/washing_machine_repair_icon.png',
      'active': true,
      'sortOrder': 11,
    },
    'home-appliance-repair': {
      'name': 'Home Appliance Repair',
      'description': 'Repair services for common household appliances',
      'iconPath': 'categories/home_appliance_repair_icon.png',
      'active': true,
      'sortOrder': 12,
    },
    'mobile-repair': {
      'name': 'Mobile Phone Repair',
      'description': 'Mobile phone hardware and software repair services',
      'iconPath': 'categories/mobile_repair_icon.png',
      'active': true,
      'sortOrder': 13,
    },
    'computer-repair': {
      'name': 'Computer Repair',
      'description': 'Desktop and laptop repair services',
      'iconPath': 'categories/computer_repair_icon.png',
      'active': true,
      'sortOrder': 14,
    },
    'television-repair': {
      'name': 'Television Repair',
      'description': 'Television diagnosis and repair services',
      'iconPath': 'categories/television_repair_icon.png',
      'active': true,
      'sortOrder': 15,
    },
    'cctv-technician': {
      'name': 'CCTV Technician',
      'description': 'Security camera installation and repair services',
      'iconPath': 'categories/cctv_technician_icon.png',
      'active': true,
      'sortOrder': 16,
    },
    'solar-panel-technician': {
      'name': 'Solar Panel Technician',
      'description': 'Solar panel installation and maintenance services',
      'iconPath': 'categories/solar_panel_technician_icon.png',
      'active': true,
      'sortOrder': 17,
    },
    'gardener': {
      'name': 'Gardener',
      'description': 'Garden maintenance and landscaping services',
      'iconPath': 'categories/gardener_icon.png',
      'active': true,
      'sortOrder': 18,
    },
    'house-cleaning': {
      'name': 'House Cleaning',
      'description': 'Residential cleaning services',
      'iconPath': 'categories/house_cleaning_icon.png',
      'active': true,
      'sortOrder': 19,
    },
    'shoe-repair': {
      'name': 'Shoe Repair',
      'description': 'Footwear repair and restoration services',
      'iconPath': 'categories/shoe_repair_icon.png',
      'active': true,
      'sortOrder': 20,
    },
  };

  for (final categoryEntry in categories.entries) {
    final categoryDocument = firestore
        .collection('categories')
        .doc(categoryEntry.key);

    batch.set(
      categoryDocument,
      categoryEntry.value,
      SetOptions(merge: true),
    );
  }

  await batch.commit();
}