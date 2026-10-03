import 'package:flutter/material.dart';

import 'provider_request_details_screen.dart';

/// Jobs use the same live request, customer, location, images and quotation view.
class ProviderJobDetailsScreen extends StatelessWidget {
  final String requestId;

  const ProviderJobDetailsScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) =>
      ProviderRequestDetailsScreen(requestId: requestId, isJob: true);
}
