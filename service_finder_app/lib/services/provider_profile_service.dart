import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class ProviderProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No signed-in provider found.');
    }

    return user.uid;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final snapshot = await _firestore
        .collection('providerProfiles')
        .doc(_uid)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  Future<String> uploadProfileImage(File file) async {
    final extension = file.path.split('.').last.toLowerCase();

    final storagePath = 'providers/$_uid/profile.$extension';

    final reference = _storage.ref().child(storagePath);

    await reference.putFile(
      file,
      SettableMetadata(contentType: 'image/$extension'),
    );

    return storagePath;
  }

  Future<String> getDownloadUrl(String storagePath) async {
    final value = storagePath.trim();
    if (value.startsWith('https://') || value.startsWith('http://')) {
      return value;
    }

    return _storage.ref().child(value).getDownloadURL();
  }

  Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw StateError(
        'Location services are disabled. Please enable location services.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw StateError('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission is permanently denied. '
        'Please enable it from app settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<String> getLocationName({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json'
      '&lat=$latitude'
      '&lon=$longitude'
      '&zoom=18'
      '&addressdetails=1',
    );

    final response = await http.get(
      uri,
      headers: const {'User-Agent': 'ServiceFinderApp/1.0'},
    );

    if (response.statusCode != 200) {
      throw StateError('Could not find the location name.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final displayName = data['display_name'];

    if (displayName is String && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    throw StateError('Location name could not be found.');
  }

  Future<void> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String bio,
    required String categoryId,
    required String locationName,
    required double serviceRadiusKm,
    required double latitude,
    required double longitude,
    String? photoStoragePath,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No signed-in provider found.');
    }

    final data = <String, dynamic>{
      'displayName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'bio': bio.trim(),
      'categoryId': categoryId,
      'locationName': locationName.trim(),
      'baseLocation': GeoPoint(latitude, longitude),
      'serviceRadiusKm': serviceRadiusKm,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (photoStoragePath != null && photoStoragePath.trim().isNotEmpty) {
      data['photoUrl'] = photoStoragePath;
    }

    await _firestore
        .collection('providerProfiles')
        .doc(_uid)
        .set(data, SetOptions(merge: true));

    await user.updateDisplayName(fullName.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
