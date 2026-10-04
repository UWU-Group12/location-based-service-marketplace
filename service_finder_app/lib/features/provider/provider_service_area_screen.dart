import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/profile_location_editor.dart';

class ProviderServiceAreaScreen extends StatelessWidget {
  final GeoPoint? location;
  final String? locationName;
  final double serviceRadiusKm;
  final Future<void> Function(GeoPoint, double) onSave;
  const ProviderServiceAreaScreen({
    super.key,
    this.location,
    this.locationName,
    required this.serviceRadiusKm,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => ProfileLocationEditor(
    title: 'Service area',
    location: location,
    locationName: locationName,
    serviceRadiusKm: serviceRadiusKm,
    onSave: (point, _, radius) => onSave(point, radius!),
  );
}
