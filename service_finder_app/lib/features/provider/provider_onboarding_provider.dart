import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProviderOnboardingProvider extends ChangeNotifier {
  // Account and personal details
  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';

  // Professional profile
  String? profileImageLocalPath;
  String? about;

  // Service information
  String selectedService = '';

  // Service availability
  int? experienceYears;
  List<String> workingDays = [];
  String workingHours = '';

  // Working location
  GeoPoint? baseLocation;
  String selectedLocationId = '';
  String selectedLocationName = '';
  double? serviceRadiusKm;

  // Local files are uploaded only when the provider confirms registration.
  String? nationalIdFrontPath;
  String? nationalIdBackPath;

  void setName({required String firstName, required String lastName}) {
    this.firstName = firstName;
    this.lastName = lastName;
    notifyListeners();
  }

  void setContact({required String email}) {
    this.email = email;
    notifyListeners();
  }

  void setPersonalDetails({
    required String phone,
    required String about,
    String? imageLocalPath,
  }) {
    this.phone = phone;
    this.about = about;
    profileImageLocalPath = imageLocalPath;
    notifyListeners();
  }

  void setService(String service) {
    selectedService = service;
    notifyListeners();
  }

  void setWorkingInformation({
    required int experienceYears,
    required List<String> workingDays,
    required String workingHours,
  }) {
    this.experienceYears = experienceYears;
    this.workingDays = List.unmodifiable(workingDays);
    this.workingHours = workingHours;
    notifyListeners();
  }

  void setLocation({
    required GeoPoint baseLocation,
    required String locationId,
    required String locationName,
    required double serviceRadiusKm,
  }) {
    this.baseLocation = baseLocation;
    selectedLocationId = locationId;
    selectedLocationName = locationName;
    this.serviceRadiusKm = serviceRadiusKm;
    notifyListeners();
  }

  void setVerificationDocuments({
    required String nationalIdFrontPath,
    required String nationalIdBackPath,
  }) {
    this.nationalIdFrontPath = nationalIdFrontPath;
    this.nationalIdBackPath = nationalIdBackPath;
    notifyListeners();
  }

  void clear() {
    firstName = '';
    lastName = '';
    email = '';
    phone = '';
    profileImageLocalPath = null;
    about = null;
    selectedService = '';
    experienceYears = null;
    workingDays = [];
    workingHours = '';
    baseLocation = null;
    selectedLocationId = '';
    selectedLocationName = '';
    serviceRadiusKm = null;
    nationalIdFrontPath = null;
    nationalIdBackPath = null;
    notifyListeners();
  }
}
