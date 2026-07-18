import 'package:flutter/material.dart';

class ProviderOnboardingProvider extends ChangeNotifier {
  // Personal Details
  String firstName = '';
  String lastName = '';

  // Contact Details
  String email = '';
  String phone = '';

  // Account Security
  String password = '';

  // Professional Profile
  String? profileImagePath;
  String? homeAddress;
  String? about;

  // Service Information
  String selectedService = '';

  // Working Information
  String experienceYears = '';
  List<String> workingDays = [];
  String workingHours = '';

  // Location
  String location = '';
  double workingRadius = 0;

  // Verification
  String nationalIdFront = '';
  String nationalIdBack = '';

  // Update personal details
  void setName({required String firstName, required String lastName}) {
    this.firstName = firstName;
    this.lastName = lastName;
    notifyListeners();
  }

  // Update contact details
  void setContact({required String email, required String phone}) {
    this.email = email;
    this.phone = phone;
    notifyListeners();
  }

  // Update password
  void setPassword({required String password}) {
    this.password = password;
    notifyListeners();
  }

  // Update professional profile
  void setPersonalDetails({
    required String about,
    String? imagePath,
    String? address,
  }) {
    homeAddress = address;
    this.about = about;
    profileImagePath = imagePath;

    notifyListeners();
  }

  // Update selected service
  void setService(String service) {
    selectedService = service;
    notifyListeners();
  }

  // Update experience and working schedule
  void setWorkingInformation({
    required String experienceYears,
    required List<String> workingDays,
    required String workingHours,
  }) {
    this.experienceYears = experienceYears;
    this.workingDays = workingDays;
    this.workingHours = workingHours;
    notifyListeners();
  }

  // Update location
  void setLocation({required String location, required double radius}) {
    this.location = location;
    workingRadius = radius;
    notifyListeners();
  }

  // Update verification documents
  void setVerificationDocuments({
    required String nationalIdFront,
    required String nationalIdBack,
  }) {
    this.nationalIdFront = nationalIdFront;
    this.nationalIdBack = nationalIdBack;
    notifyListeners();
  }

  // Clear all data if onboarding is cancelled
  void clear() {
    firstName = '';
    lastName = '';

    email = '';
    phone = '';

    password = '';

    profileImagePath = null;
    homeAddress = null;
    about = null;

    selectedService = '';

    experienceYears = '';
    workingDays = [];
    workingHours = '';

    location = '';
    workingRadius = 0;

    nationalIdFront = '';
    nationalIdBack = '';

    notifyListeners();
  }
}
