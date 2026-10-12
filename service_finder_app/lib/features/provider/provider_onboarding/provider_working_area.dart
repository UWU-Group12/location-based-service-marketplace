import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'provider_onboarding_layout.dart';
import 'package:provider/provider.dart';

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
  String? _locationName;
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
    if (_currentLocation != null) _loadLocationName(_currentLocation!);
  }

  Future<void> _loadLocationName(GeoPoint point) async {
    final name = await _locationService.getAddressFromGeoPoint(point);
    if (!mounted || point != _currentLocation) return;
    setState(() => _locationName = name);
  }

  // 1. Live GPS Locator
  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);

    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;

      setState(() {
        _currentLocation = location;
        _locationName = null;
      });
      _loadLocationName(location);
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

  // 2. Map Picker Locator
  Future<void> _openMapPicker() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);

    try {
      final picked = await _locationService.pickLocationOnMap(
        context,
        initial: _currentLocation,
      );

      if (!mounted) return;

      if (picked != null) {
        setState(() {
          _currentLocation = picked;
          _locationName = null;
        });
        _loadLocationName(picked);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location selected from map.')),
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

    Provider.of<ProviderOnboardingProvider>(
      context,
      listen: false,
    ).setLocation(baseLocation: currentLocation, serviceRadiusKm: radiusKm);

    AppRouter.goToVerificationDocuments(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildLocationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerLeft, child: _buildRadiusSelector()),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isGettingLocation ? null : _useCurrentLocation,
                icon: _isGettingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: Text(_isGettingLocation ? 'Detecting...' : 'Use GPS'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isGettingLocation ? null : _openMapPicker,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Pick on Map'),
              ),
            ),
          ],
        ),

        if (_currentLocation != null) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _locationName ?? 'Location successfully saved.',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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

  Widget _buildRadiusSelector() {
    const selectorWidth = 220.0;
    final label = _selectedRadiusKm == null
        ? 'Service radius'
        : '${_selectedRadiusKm!.toInt()} km radius';

    return PopupMenuButton<double>(
      tooltip: 'Service radius',
      enabled: !_isGettingLocation,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      elevation: 8,
      color: Colors.white,
      constraints: const BoxConstraints(
        minWidth: selectorWidth,
        maxWidth: selectorWidth,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: (value) => setState(() => _selectedRadiusKm = value),
      itemBuilder: (context) => _radiusOptions
          .map(
            (radius) => PopupMenuItem<double>(
              value: radius,
              child: Row(
                children: [
                  const Icon(
                    Icons.radar_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${radius.toInt()} km')),
                  if (_selectedRadiusKm == radius)
                    const Icon(Icons.check, size: 18),
                ],
              ),
            ),
          )
          .toList(),
      child: Opacity(
        opacity: _isGettingLocation ? 0.55 : 1,
        child: Container(
          width: selectorWidth,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.providerCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.radar_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      resizeToAvoidBottomInset: true,
      body: ProviderOnboardingBody(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            const ProviderOnboardingHeroText(
              segments: [
                ProviderOnboardingHeroSegment('Set'),
                ProviderOnboardingHeroSegment('your'),
                ProviderOnboardingHeroSegment('working', muted: true),
                ProviderOnboardingHeroSegment('area'),
              ],
            ),
            const SizedBox(height: 34),
            _buildLocationForm(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
