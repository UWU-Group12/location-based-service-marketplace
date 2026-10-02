import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../location_picker_screen.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';
import '../../../services/location_service.dart';
import '../provider_onboarding_provider.dart';

class ProviderWorkingArea extends StatefulWidget {
  const ProviderWorkingArea({super.key});

  @override
  State<ProviderWorkingArea> createState() => _ProviderWorkingAreaState();
}

class _ProviderWorkingAreaState extends State<ProviderWorkingArea> {
  static const List<double> _radiusOptions = [5, 10, 15, 20, 30];

  final LocationService _locationService = LocationService();

  double? _selectedRadiusKm;
  GeoPoint? _currentLocation;
  bool _isGettingLocation = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final onboarding = Provider.of<ProviderOnboardingProvider>(
      context,
      listen: false,
    );
    _selectedRadiusKm = onboarding.serviceRadiusKm;
    _currentLocation = onboarding.baseLocation;
    _initialized = true;
  }

  // 1. Live GPS Locator
  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);

    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;

      setState(() => _currentLocation = location);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location selected.')),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.toString())),
      );
    } catch (error) {
      debugPrint('Provider location error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get your location. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  // 2. Map Picker Locator
  Future<void> _openMapPicker() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);

    try {
      final currentPoint = await _locationService.getCurrentLocation();
      final initialPos = LatLng(currentPoint.latitude, currentPoint.longitude);

      if (!mounted) return;

      final LatLng? picked = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationPickerScreen(initialLocation: initialPos),
        ),
      );

      if (!mounted) return;

      if (picked != null) {
        setState(() {
          _currentLocation = GeoPoint(picked.latitude, picked.longitude);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location selected from map ✅')),
        );
      }
    } catch (error) {
      debugPrint('Provider map error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open map. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  void _continue() {
    final radiusKm = _selectedRadiusKm;
    final currentLocation = _currentLocation;

    if (radiusKm == null) {
      _showMessage('Please select your service radius.');
      return;
    }
    if (currentLocation == null) {
      _showMessage('Please select a location before continuing.');
      return;
    }

    Provider.of<ProviderOnboardingProvider>(context, listen: false).setLocation(
      baseLocation: currentLocation,
      serviceRadiusKm: radiusKm,
    );

    AppRouter.goToVerificationDocuments(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildLocationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<double>(
          initialValue: _selectedRadiusKm,
          decoration: const InputDecoration(
            labelText: 'Service radius',
            prefixIcon: Icon(Icons.radar_outlined),
          ),
          items: _radiusOptions
              .map(
                (radius) => DropdownMenuItem(
              value: radius,
              child: Text('${radius.toInt()} km'),
            ),
          )
              .toList(),
          onChanged: _isGettingLocation
              ? null
              : (value) => setState(() => _selectedRadiusKm = value),
        ),
        const SizedBox(height: 24),

        // 📍 Button 1: Live GPS
        OutlinedButton.icon(
          onPressed: _isGettingLocation ? null : _useCurrentLocation,
          icon: _isGettingLocation
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.my_location),
          label: Text(
            _isGettingLocation ? 'Getting Location...' : 'Use Live GPS Location',
          ),
        ),
        const SizedBox(height: 12),

        // 📍 Button 2: Map Picker
        OutlinedButton.icon(
          onPressed: _isGettingLocation ? null : _openMapPicker,
          icon: const Icon(Icons.map, color: Colors.green),
          label: const Text(
            'Select Location on Map 🗺️',
            style: TextStyle(color: Colors.green),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.green),
          ),
        ),

        if (_currentLocation != null) ...[
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Location successfully saved! ✅'),
            ],
          ),
        ],
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _isGettingLocation ? null : _continue,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primary,
            size: 20,
          ),
          onPressed: _isGettingLocation ? null : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            const Center(
              child: Icon(
                Icons.location_on_outlined,
                size: 110,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              'Set your working area',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose how far you travel and capture your current location.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 35),
            _buildLocationForm(), // 👈 Directly calling the form with no FutureBuilder
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}