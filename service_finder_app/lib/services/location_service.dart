import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<GeoPoint> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw StateError('Please turn on GPS and try again.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw StateError(
          'Location permission was denied. Please allow it to continue.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw StateError(
          'Location permission is permanently denied. Enable it in your '
          'device settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return GeoPoint(position.latitude, position.longitude);
    } on StateError {
      rethrow;
    } catch (error) {
      debugPrint('Current location error: $error');
      throw StateError(
        'Unable to get your current location. Please try again.',
      );
    }
  }
}
