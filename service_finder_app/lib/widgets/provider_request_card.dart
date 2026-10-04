import 'package:flutter/material.dart';

import '../models/quotation_model.dart';
import '../models/service_request_model.dart';
import 'request_card.dart';

/// Provider request variants use the same card as jobs and customer requests.
class ProviderRequestCard extends StatelessWidget {
  final ServiceRequestModel? request;
  final QuotationModel? quotation;
  final VoidCallback onTap;

  const ProviderRequestCard.received({
    super.key,
    required ServiceRequestModel this.request,
    required this.onTap,
  }) : quotation = null;

  const ProviderRequestCard.sent({
    super.key,
    required this.request,
    required QuotationModel this.quotation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => quotation == null
      ? RequestCard.received(request: request!, onTap: onTap)
      : RequestCard.sent(request: request, quotation: quotation!, onTap: onTap);
}
