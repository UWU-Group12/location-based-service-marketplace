import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';
import '../../../models/location_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/location_service.dart';
import '../provider_onboarding_provider.dart';

class ProviderWorkingArea extends StatefulWidget {
  const ProviderWorkingArea({super.key});

  @override
  State<ProviderWorkingArea> createState() => _ProviderWorkingAreaState();
}

class _ProviderWorkingAreaState extends State<ProviderWorkingArea> {
  static const List<double> _radiusOptions = [5, 10, 15, 20, 30];

  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  late Future<List<SupportedLocation>> _locationsFuture;
  String? _selectedLocationId;
  double? _selectedRadiusKm;
  GeoPoint? _currentLocation;
  bool _isGettingLocation = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _locationsFuture = _firestoreService.getActiveLocations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final onboarding = Provider.of<ProviderOnboardingProvider>(
      context,
      listen: false,
    );
    _selectedLocationId = onboarding.selectedLocationId.isEmpty
        ? null
        : onboarding.selectedLocationId;
    _selectedRadiusKm = onboarding.serviceRadiusKm;
    _currentLocation = onboarding.baseLocation;
    _initialized = true;
  }

  void _reloadLocations() {
    setState(() {
      _locationsFuture = _firestoreService.getActiveLocations();
    });
  }

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
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

  void _continue(List<SupportedLocation> locations) {
    final locationId = _selectedLocationId;
    final radiusKm = _selectedRadiusKm;
    final currentLocation = _currentLocation;

    if (locationId == null) {
      _showMessage('Please select a supported town.');
      return;
    }
    if (radiusKm == null) {
      _showMessage('Please select your service radius.');
      return;
    }
    if (currentLocation == null) {
      _showMessage('Please use your current location before continuing.');
      return;
    }

    final selectedLocation = locations.where(
      (location) => location.id == locationId,
    );
    if (selectedLocation.isEmpty) {
      _showMessage('The selected town is no longer available.');
      return;
    }

    Provider.of<ProviderOnboardingProvider>(context, listen: false).setLocation(
      baseLocation: currentLocation,
      locationId: locationId,
      locationName: selectedLocation.first.name,
      serviceRadiusKm: radiusKm,
    );

    AppRouter.goToVerificationDocuments(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildLocationForm(List<SupportedLocation> locations) {
    if (locations.isEmpty) {
      return Column(
        children: [
          const Text(
            'No supported towns are available right now.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _reloadLocations,
            icon: const Icon(Icons.refresh),
            label: const Text('Reload'),
          ),
        ],
      );
    }

    final selectedLocationExists = locations.any(
      (location) => location.id == _selectedLocationId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedLocationExists ? _selectedLocationId : null,
          decoration: const InputDecoration(
            labelText: 'Supported town',
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
          items: locations
              .map(
                (location) => DropdownMenuItem(
                  value: location.id,
                  child: Text(location.name),
                ),
              )
              .toList(),
          onChanged: _isGettingLocation
              ? null
              : (value) => setState(() => _selectedLocationId = value),
        ),
        const SizedBox(height: 20),
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
            _isGettingLocation ? 'Getting Location...' : 'Use Current Location',
          ),
        ),
        if (_currentLocation != null) ...[
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Current location selected'),
            ],
          ),
        ],
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _isGettingLocation ? null : () => _continue(locations),
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
              'Select a supported town, choose how far you travel, and capture '
              'your current location.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 35),
            FutureBuilder<List<SupportedLocation>>(
              future: _locationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint('Supported locations error: ${snapshot.error}');
                  return Column(
                    children: [
                      const Text(
                        'Unable to load supported towns. Please try again.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _reloadLocations,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  );
                }

                return _buildLocationForm(snapshot.data ?? const []);
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
