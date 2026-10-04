import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_colors.dart';
import 'profile_settings.dart';

String requestStatusLabel(String value) => value
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

String requestDateLabel(BuildContext context, DateTime? value) =>
    value == null || value.millisecondsSinceEpoch == 0
    ? 'Not provided'
    : MaterialLocalizations.of(context).formatMediumDate(value.toLocal());

String requestDateTimeLabel(BuildContext context, DateTime? value) =>
    value == null || value.millisecondsSinceEpoch == 0
    ? 'Not provided'
    : '${requestDateLabel(context, value)} at ${TimeOfDay.fromDateTime(value.toLocal()).format(context)}';

class RequestStateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  const RequestStateView({
    super.key,
    required this.title,
    this.message = '',
    required this.icon,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
        ],
      ),
    ),
  );
}

class RequestDetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const RequestDetailCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

class RequestDetailField extends StatelessWidget {
  final String label;
  final String? value;

  const RequestDetailField(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value == null || value!.trim().isEmpty ? 'Not provided' : value!,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    ),
  );
}

// Grey heading above a white rounded group, matching the profile screen.
class RequestSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const RequestSection(this.title, this.children, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ProfileSettingsGroup(children: children),
      ],
    ),
  );
}

// View-only map of the service location; the pin cannot be moved.
class RequestLocationMap extends StatelessWidget {
  final GeoPoint point;

  const RequestLocationMap({super.key, required this.point});

  @override
  Widget build(BuildContext context) {
    // GeoPoint(0, 0) is the model fallback when no location was saved.
    if (point.latitude == 0 && point.longitude == 0) {
      return const SizedBox.shrink();
    }
    final location = LatLng(point.latitude, point.longitude);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 200,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: location,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.group12.service_finder_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: location,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pill-shaped top tabs shared by the request and job lists.
class RequestTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> labels;

  const RequestTabBar({
    super.key,
    required this.controller,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.providerCard,
      borderRadius: BorderRadius.circular(30),
    ),
    child: TabBar(
      controller: controller,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(30),
      ),
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.primary,
      tabs: [for (final label in labels) Tab(text: label)],
    ),
  );
}
