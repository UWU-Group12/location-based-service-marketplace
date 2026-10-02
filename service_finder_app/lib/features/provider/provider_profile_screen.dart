import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_router.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import 'location_picker_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final AuthService _authService = AuthService();

  bool _isLoggingOut = false;
  bool _showLocationOptions = false;
  String _locationStatus = "";

  Future<void> _testLocation() async {
    setState(() {
      _locationStatus = "Fetching GPS coordinates... ⏳";
    });

    try {
      final locationService = LocationService();
      GeoPoint point = await locationService.getCurrentLocation();
      String? address = await locationService.getAddressFromGeoPoint(point);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('providerProfiles')
            .doc(user.uid)
            .update({
          'baseLocation': point,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      setState(() {
        _locationStatus =
        "📍 Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}\n🏙️ City: $address\n✅ Saved to Firestore!";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationStatus = "❌ Error: $e";
      });
    }
  }

  Future<void> _openMapPicker() async {
    try {
      final locationService = LocationService();
      GeoPoint currentPoint = await locationService.getCurrentLocation();
      LatLng initialPos =
      LatLng(currentPoint.latitude, currentPoint.longitude);

      if (!mounted) return; // 👈 Required check before Navigator.push

      final LatLng? picked = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LocationPickerScreen(initialLocation: initialPos),
        ),
      );

      if (!mounted) return;

      if (picked != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          GeoPoint newPoint = GeoPoint(picked.latitude, picked.longitude);
          String? address =
          await locationService.getAddressFromGeoPoint(newPoint);

          await FirebaseFirestore.instance
              .collection('providerProfiles')
              .doc(user.uid)
              .update({
            'baseLocation': newPoint,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (!mounted) return;

          setState(() {
            _locationStatus =
            "📍 Pin Selected!\nLat: ${picked.latitude.toStringAsFixed(4)}, Lng: ${picked.longitude.toStringAsFixed(4)}\n🏙️ City: $address\n✅ Saved to Firestore!";
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationStatus = "❌ Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile Service Provider")),
      body: StreamBuilder(
        stream: _authService.user,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          if (user == null) {
            return const Center(
              child: Text('No user is currently signed in.'),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.email ?? 'No email',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showLocationOptions = !_showLocationOptions;
                      });
                    },
                    icon: const Icon(Icons.edit_location_alt),
                    label: Text(_showLocationOptions
                        ? 'Hide Location Options'
                        : 'Change Location 📍'),
                  ),
                  if (_showLocationOptions) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _testLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text("Test Live GPS Location"),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.map),
                      label: const Text("Select Location on Map 🗺️"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_locationStatus.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _locationStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    icon: _isLoggingOut
                        ? const SizedBox(
                      width: 26,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.logout),
                    label:
                    Text(_isLoggingOut ? 'Logging out...' : 'Logout'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.signOut();

      if (!mounted) return;

      AppRouter.goToLoginAfterLogout(context);
    } catch (error) {
      debugPrint('Logout error: $error');

      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to log out. Please try again.'),
        ),
      );
    }
  }
}