import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

class CustomerProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  /// Get customer profile from Firestore
  Future<Map<String, dynamic>> getProfile() async {
    final user = currentUser;

    if (user == null) {
      throw StateError('User is not signed in.');
    }

    final snapshot = await _firestore.collection('users').doc(user.uid).get();

    if (!snapshot.exists) {
      return {
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'photoUrl': user.photoURL ?? '',
        'locationName': '',
        'latitude': null,
        'longitude': null,
      };
    }

    return snapshot.data() ?? {};
  }

  /// Update customer profile
  Future<void> updateProfile({
    required String name,
    required String locationName,
    required double? latitude,
    required double? longitude,
    String? phoneNumber,
    String? photoUrl,
    bool clearPhoto = false,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw StateError('User is not signed in.');
    }

    final Map<String, dynamic> data = {
      'displayName': name.trim(),
      'locationName': locationName.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (phoneNumber != null) {
      data['phoneNumber'] = phoneNumber.trim();
    }

    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
    }
    if (clearPhoto) {
      data['photoUrl'] = '';
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));

    // Update Firebase Auth display name.
    await user.updateDisplayName(name.trim());

    if (clearPhoto || photoUrl != null) {
      await user.updatePhotoURL(clearPhoto ? null : photoUrl);
    }
  }

  /// Upload customer profile image
  Future<String> uploadProfileImage(File file) async {
    final user = currentUser;

    if (user == null) {
      throw StateError('User is not signed in.');
    }

    final extension = file.path.split('.').last.toLowerCase();
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    final storageRef = _storage.ref().child(
      'customers/${user.uid}/profile_$timestamp.$extension',
    );

    await storageRef.putFile(
      file,
      SettableMetadata(contentType: 'image/$extension'),
    );

    return await storageRef.getDownloadURL();
  }

  /// Accept both previously stored download URLs and Firebase Storage paths.
  Future<String> getProfileImageUrl(String imageUrlOrPath) {
    final value = imageUrlOrPath.trim();
    if (value.startsWith('https://') || value.startsWith('http://')) {
      return Future.value(value);
    }

    return _storage.ref().child(value).getDownloadURL();
  }

  /// Get current GPS location.
  Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw StateError(
        'Location service is disabled. Please enable location services.',
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
        'Please enable it from Settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Change password
  Future<void> changePassword({required String newPassword}) async {
    final user = currentUser;

    if (user == null) {
      throw StateError('User is not signed in.');
    }

    await user.updatePassword(newPassword);
  }
}
