import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderModel {
  final String providerId;
  final String displayName;
  final String? profileImagePath;
  final String? bio;
  final List<String> categoryIds;
  final int experienceYears;
  final List<String> workingDays;
  final String workingHours;
  final GeoPoint? baseLocation;
  final String? geohash;
  final String? locationId;
  final double? serviceRadiusKm;
  final String availabilityStatus;
  final String verificationStatus;
  final double ratingAverage;
  final int reviewCount;
  final int completedJobCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProviderModel({
    required this.providerId,
    required this.displayName,
    this.profileImagePath,
    this.bio,
    required this.categoryIds,
    this.experienceYears = 0,
    this.workingDays = const [],
    this.workingHours = '',
    this.baseLocation,
    this.geohash,
    this.locationId,
    this.serviceRadiusKm,
    required this.availabilityStatus,
    required this.verificationStatus,
    required this.ratingAverage,
    required this.reviewCount,
    required this.completedJobCount,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'providerId': providerId,
      'displayName': displayName,
      if (profileImagePath != null) 'profileImagePath': profileImagePath,
      if (bio != null) 'bio': bio,
      'categoryIds': categoryIds,
      'experienceYears': experienceYears,
      'workingDays': workingDays,
      'workingHours': workingHours,
      if (baseLocation != null) 'baseLocation': baseLocation,
      if (geohash != null) 'geohash': geohash,
      if (locationId != null) 'locationId': locationId,
      if (serviceRadiusKm != null) 'serviceRadiusKm': serviceRadiusKm,
      'availabilityStatus': availabilityStatus,
      'verificationStatus': verificationStatus,
      'ratingAverage': ratingAverage,
      'reviewCount': reviewCount,
      'completedJobCount': completedJobCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ProviderModel.fromFirestore(String docId, Map<String, dynamic> data) {
    return ProviderModel(
      providerId: docId,
      displayName: data['displayName'] ?? '',
      profileImagePath: data['profileImagePath'],
      bio: data['bio'],
      categoryIds: List<String>.from(data['categoryIds'] ?? []),
      experienceYears: (data['experienceYears'] as num?)?.toInt() ?? 0,
      workingDays: List<String>.from(data['workingDays'] ?? []),
      workingHours: data['workingHours'] as String? ?? '',
      baseLocation: data['baseLocation'] as GeoPoint?,
      geohash: data['geohash'] as String?,
      locationId: data['locationId'] as String?,
      serviceRadiusKm: (data['serviceRadiusKm'] as num?)?.toDouble(),
      availabilityStatus: data['availabilityStatus'] ?? 'unavailable',
      verificationStatus: data['verificationStatus'] ?? 'not_submitted',
      ratingAverage: (data['ratingAverage'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      completedJobCount: data['completedJobCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
