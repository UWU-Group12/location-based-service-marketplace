class ServiceProviderModel {
  final String id;
  final String name;
  final String service;
  final String location;
  final double rating;
  final int experience;
  final String image;
  final bool isVerified;

  const ServiceProviderModel({
    required this.id,
    required this.name,
    required this.service,
    required this.location,
    required this.rating,
    required this.experience,
    required this.image,
    required this.isVerified,
  });
}