import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Fetches current GPS coordinates as a Firestore GeoPoint
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

  /// Converts a GeoPoint into a city/locality name (e.g., "Badulla, Sri Lanka")
  Future<String?> getAddressFromGeoPoint(GeoPoint geoPoint) async {
    try {
      // 1. Create the Geocoding instance (Required for v5.0.0+)
      final geocoding = Geocoding();

      // 2. Call the method using the new instance
      List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(
        geoPoint.latitude,
        geoPoint.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.locality ?? place.subAdministrativeArea}, ${place.country}";
      }
    } catch (error) {
      debugPrint('Address lookup error: $error');
    }
    return null;
  }
}