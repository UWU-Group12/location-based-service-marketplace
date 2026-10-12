import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/profile_location_editor.dart';

class SavedLocationScreen extends StatelessWidget {
  final GeoPoint? location;
  final String? locationName;
  final Future<void> Function(GeoPoint, String) onSave;
  const SavedLocationScreen({
    super.key,
    this.location,
    this.locationName,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => ProfileLocationEditor(
    title: 'Saved location',
    location: location,
    locationName: locationName,
    onSave: (point, name, _) => onSave(point, name),
  );
}
