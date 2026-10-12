import 'package:flutter/material.dart';

import '../../models/provider_model.dart';
import '../../services/firestore_service.dart';
import 'provider_shell_screen.dart';
import 'provider_verification_status_screen.dart';

class ProviderHomeGate extends StatelessWidget {
  final String providerId;

  const ProviderHomeGate({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProviderModel?>(
      stream: FirestoreService().watchProviderProfile(providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final provider = snapshot.data;
        final status = provider?.verificationStatus ?? 'pending';

        if (status.trim().toLowerCase() == 'verified') {
          return const ProviderShellScreen();
        }

        return ProviderVerificationStatusScreen(verificationStatus: status);
      },
    );
  }
}
