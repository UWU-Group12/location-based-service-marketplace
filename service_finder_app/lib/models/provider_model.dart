import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderModel {

  final String providerId;
  final String displayName;
  final String? profileImagePath;
  final String? bio;
  final List<String> categoryIds;
  final GeoPoint baseLocation;
  final String geohash;
  final String locationId;
  final double serviceRadiusKm;
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
    required this.categoryIds,   //cat001,cat002
    required this.baseLocation,  // get the location using geopoint in firebase
    required this.geohash,     // this turn the geopoint into a code
    required this.locationId,  //Show all providers in Colombo
    required this.serviceRadiusKm, // how far the provider is willing to travel.
    required this.availabilityStatus, //can use enum too
    required this.verificationStatus, //verified or not
    required this.ratingAverage, //4.7 stars , use a review page to calculate the ratings
    required this.reviewCount, //13 reviews
    required this.completedJobCount, //12 jobs done
    required this.createdAt, //profile creation time
    required this.updatedAt, //profile updated 2 hours ago
  });

  Map<String, dynamic> toFirestore(){
    return{
      'providerId': providerId,
      'displayName': displayName,
      'profileImagePath': profileImagePath,
      'bio': bio,
      'categoryIds': categoryIds,
      'baseLocation': baseLocation,
      'geohash': geohash,
      'locationId': locationId,
      'serviceRadiusKm': serviceRadiusKm,
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
      baseLocation: data['baseLocation'] ?? const GeoPoint(0,0),
      geohash: data['geohash'] ?? '',
      locationId: data['locationId'] ?? '',
      serviceRadiusKm: (data['serviceRadiusKm'] ?? 0.0).toDouble(),
      availabilityStatus: data['availabilityStatus'] ?? 'available',
      verificationStatus: data['verificationStatus'] ?? 'not_submitted',
      ratingAverage: (data['ratingAverage'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      completedJobCount: data['completedJobCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

}