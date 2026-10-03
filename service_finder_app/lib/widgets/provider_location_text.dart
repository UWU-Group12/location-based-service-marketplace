import 'package:flutter/material.dart';

import '../models/provider_model.dart';
import '../services/location_service.dart';

class ProviderLocationText extends StatefulWidget {
  final ProviderModel provider;

  const ProviderLocationText({super.key, required this.provider});

  @override
  State<ProviderLocationText> createState() => _ProviderLocationTextState();
}

class _ProviderLocationTextState extends State<ProviderLocationText> {
  final LocationService _locationService = LocationService();

  late Future<String?> _addressFuture;

  @override
  void initState() {
    super.initState();
    _addressFuture = _loadAddress();
  }

  @override
  void didUpdateWidget(ProviderLocationText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.provider.baseLocation != widget.provider.baseLocation) {
      _addressFuture = _loadAddress();
    }
  }

  Future<String?> _loadAddress() {
    final baseLocation = widget.provider.baseLocation;

    if (baseLocation == null) {
      return Future.value(null);
    }

    return _locationService.getAddressFromGeoPoint(baseLocation);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _addressFuture,
      builder: (context, snapshot) {
        final address = snapshot.data;

        if (snapshot.hasError || address == null || address.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}