import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../features/provider/location_picker_screen.dart';
import 'auth_service.dart';

class LocationService {
  // Shared across instances since screens create their own LocationService
  static final Map<String, String> _addressCache = {};

  // Used as the map start point when GPS is unavailable (Colombo)
  static const GeoPoint _defaultMapCenter = GeoPoint(6.9271, 79.8612);

  /// Opens the OpenStreetMap picker and returns the chosen point, or null
  /// if the user backs out. Starts at [initial], else GPS, else Colombo.
  Future<GeoPoint?> pickLocationOnMap(
    BuildContext context, {
    GeoPoint? initial,
  }) async {
    var start = initial;
    if (start == null) {
      try {
        start = await getCurrentLocation();
      } catch (_) {
        start = _defaultMapCenter;
      }
    }

    if (!context.mounted) return null;

    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: LatLng(start!.latitude, start.longitude),
        ),
      ),
    );

    if (picked == null) return null;
    return GeoPoint(picked.latitude, picked.longitude);
  }

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

  /// GPS first; falls back to the signed-in user's saved location, else null
  Future<GeoPoint?> getCurrentOrSavedLocation() async {
    try {
      return await getCurrentLocation();
    } catch (error) {
      debugPrint('Current location unavailable: $error');
    }

    try {
      return (await AuthService().getUserProfileForCurrentUser())
          ?.savedLocation;
    } catch (error) {
      debugPrint('Saved location error: $error');
      return null;
    }
  }

  /// Converts a GeoPoint into a city/locality name (e.g., "Badulla, Sri Lanka")
  Future<String?> getAddressFromGeoPoint(GeoPoint geoPoint) async {
    final cacheKey =
        '${geoPoint.latitude.toStringAsFixed(4)},'
        '${geoPoint.longitude.toStringAsFixed(4)}';

    final cachedAddress = _addressCache[cacheKey];
    if (cachedAddress != null) {
      return cachedAddress;
    }

    try {
      final geocoding = Geocoding();

      final placemarks = await geocoding.placemarkFromCoordinates(
        geoPoint.latitude,
        geoPoint.longitude,
      );

      if (placemarks.isEmpty) {
        return null;
      }

      final place = placemarks.first;
      final locality = place.locality ?? place.subAdministrativeArea;

      if (locality == null || locality.isEmpty) {
        return null;
      }

      final address = '$locality, ${place.country}';
      _addressCache[cacheKey] = address;

      return address;
    } catch (error) {
      debugPrint('Address lookup error: $error');
      return null;
    }
  }
}
