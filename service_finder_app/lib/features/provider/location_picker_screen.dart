import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const LocationPickerScreen({super.key, required this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _pickedLocation;

  @override
  void initState() {
    super.initState();
    // Start the pin at their current GPS location
    _pickedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Your Location"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green, size: 30),
            onPressed: () {
              // Return the picked location back to the previous screen
              Navigator.of(context).pop(_pickedLocation);
            },
          )
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _pickedLocation,
          initialZoom: 15.0,
          onTap: (tapPosition, point) {
            setState(() {
              _pickedLocation = point; // Move pin when user taps the map
            });
          },
        ),
        children: [
          TileLayer(
            // The free OpenStreetMap URL
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.group12.service_finder_app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _pickedLocation,
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}