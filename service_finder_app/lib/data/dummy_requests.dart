import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_request_model.dart';

final List<ServiceRequestModel> dummyRequests = [

  ServiceRequestModel(
    requestId: '1',
    customerId: 'customer_001',
    providerId: 'provider_001',
    categoryId: 'plumbing',
    title: 'Kitchen Pipe Leakage',
    description: 'Water leaking from kitchen sink pipe.',
    imagePaths: [],
    servicePoint: const GeoPoint(7.8731, 80.7718),
    serviceGeohash: 'temporary',
    addressText: 'Badulla',
    requestStatus: 'submitted',
    quotationStatus: 'pending',
    finalAmount: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),

  ServiceRequestModel(
    requestId: '2',
    customerId: 'customer_001',
    providerId: 'provider_002',
    categoryId: 'electrical',
    title: 'Ceiling Fan Repair',
    description: 'Fan making unusual noise.',
    imagePaths: [],
    servicePoint: const GeoPoint(6.9271, 79.8612),
    serviceGeohash: 'temporary',
    addressText: 'Colombo',
    requestStatus: 'quotation_received',
    quotationStatus: 'sent',
    finalAmount: 5000,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),

];