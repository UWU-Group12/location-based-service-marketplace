import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/location_service.dart';
import 'profile_editor_scaffold.dart';

class ProfileLocationEditor extends StatefulWidget {
  final String title;
  final GeoPoint? location;
  final String? locationName;
  final double? serviceRadiusKm;
  final Future<void> Function(GeoPoint, String, double?) onSave;

  const ProfileLocationEditor({
    super.key,
    required this.title,
    this.location,
    this.locationName,
    this.serviceRadiusKm,
    required this.onSave,
  });

  @override
  State<ProfileLocationEditor> createState() => _ProfileLocationEditorState();
}

class _ProfileLocationEditorState extends State<ProfileLocationEditor> {
  late GeoPoint? _location = widget.location;
  late String _locationName =
      widget.locationName ?? _coordinates(widget.location);
  late double? _radius = widget.serviceRadiusKm;
  bool _locating = false;
  bool _saving = false;

  String _coordinates(GeoPoint? point) => point == null
      ? ''
      : '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';

  Future<void> _selectLocation({bool fromMap = false}) async {
    if (_locating || _saving) return;
    setState(() => _locating = true);
    try {
      final service = LocationService();
      final point = fromMap
          ? await service.pickLocationOnMap(context, initial: _location)
          : await service.getCurrentLocation();
      if (!mounted || point == null) return;
      final address = await service.getAddressFromGeoPoint(point);
      if (!mounted) return;
      setState(() {
        _location = point;
        _locationName = address ?? _coordinates(point);
      });
    } catch (error) {
      if (mounted) {
        _message(
          error is StateError
              ? error.message
              : 'Could not select your location.',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _locating) return;
    if (_location == null) {
      _message('Please choose your location using GPS or the map.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(_location!, _locationName, _radius);
      if (!mounted) return;
      setState(() => _saving = false);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _message('Could not save your location. Please try again.');
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => ProfileEditorScaffold(
    title: widget.title,
    saving: _saving,
    busy: _locating,
    onSave: _save,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Location',
            prefixIcon: Icon(Icons.place_outlined),
          ),
          child: Text(
            _locationName.isEmpty ? 'Choose a location' : _locationName,
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _locating ? null : _selectLocation,
          icon: _locating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location_outlined),
          label: Text(_locating ? 'Getting location…' : 'Use current location'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _locating ? null : () => _selectLocation(fromMap: true),
          icon: const Icon(Icons.map_outlined),
          label: const Text('Pick on map'),
        ),
        if (_radius != null) ...[
          const SizedBox(height: 28),
          const Text(
            'Service radius',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5.0, 10.0, 15.0, 20.0, 30.0]
                .map(
                  (radius) => ChoiceChip(
                    label: Text('${radius.toInt()} km'),
                    selected: _radius == radius,
                    onSelected: (_) => setState(() => _radius = radius),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    ),
  );
}
