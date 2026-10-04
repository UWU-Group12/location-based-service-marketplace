import 'package:flutter/material.dart';

import '../../widgets/profile_settings.dart';
import 'provider_profile_status_controller.dart';

class ProviderStatusSection extends StatelessWidget {
  final ProviderProfileStatusController controller;
  const ProviderStatusSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final profile = controller.profile;
      final verification = profile == null
          ? 'Status unavailable'
          : switch (profile.verificationStatus) {
              'verified' => 'Verified',
              'rejected' => 'Rejected',
              'not_submitted' => 'Not verified',
              _ => 'Pending',
            };
      return Column(
        children: [
          ProfileSettingsRow(
            icon: Icons.verified_outlined,
            title: 'Verification',
            value: verification,
          ),
          const Divider(height: 1, indent: 56, endIndent: 18),
          ProfileSettingsRow(
            icon: Icons.work_outline,
            title: 'Availability',
            value: profile == null
                ? 'Status unavailable'
                : profile.availabilityStatus == 'available'
                ? 'Available'
                : 'Not available',
          ),
          if (controller.hasError)
            TextButton.icon(
              onPressed: controller.retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Could not refresh status. Try again'),
            ),
        ],
      );
    },
  );
}
