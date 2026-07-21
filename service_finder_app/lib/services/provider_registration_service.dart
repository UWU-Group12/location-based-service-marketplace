import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/provider_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'storage_service.dart';

class ProviderRegistrationService {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  ProviderRegistrationService({
    AuthService? authService,
    FirestoreService? firestoreService,
    StorageService? storageService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService(),
       _storageService = storageService ?? StorageService();

  Future<UserModel> createProviderAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final displayName = '$firstName $lastName'.trim();
    final cleanEmail = email.trim();

    if (displayName.isEmpty || cleanEmail.isEmpty || password.isEmpty) {
      throw StateError('Name, email, and password are required.');
    }

    final authenticatedUser = _authService.currentUser;
    if (authenticatedUser != null) {
      final existingProfile = await _authService.getUserProfile(
        authenticatedUser.uid,
      );

      if (existingProfile == null) {
        return _authService.createCurrentUserProfile(UserRole.provider);
      }
      if (!existingProfile.isProvider) {
        throw StateError('The signed-in account is not a provider account.');
      }

      return _authService.requireActiveUserProfile(existingProfile.id);
    }

    final result = await _authService.registerWithEmail(cleanEmail, password, {
      'displayName': displayName,
      'email': cleanEmail,
      'role': UserRole.provider.name,
      'accountStatus': AccountStatus.active.name,
      'profileCompleted': false,
    });
    final firebaseUser = result.user;

    if (firebaseUser == null) {
      throw StateError('Firebase did not return the registered user.');
    }

    return _authService.requireActiveUserProfile(firebaseUser.uid);
  }

  Future<UserModel> completeProviderProfile({
    required String phoneNumber,
    required String bio,
    String? profileImageLocalPath,
    required String categoryId,
    required int experienceYears,
    required List<String> workingDays,
    required String workingHours,
    required GeoPoint baseLocation,
    required String locationId,
    required double serviceRadiusKm,
    required String nationalIdFrontPath,
    required String nationalIdBackPath,
  }) async {
    final cleanCategoryId = categoryId.trim();
    final cleanPhoneNumber = phoneNumber.trim();
    final cleanWorkingHours = workingHours.trim();
    final cleanLocationId = locationId.trim();
    final cleanWorkingDays = workingDays
        .map((day) => day.trim())
        .where((day) => day.isNotEmpty)
        .toList(growable: false);

    if (cleanCategoryId.isEmpty) {
      throw StateError('Please select a service category.');
    }
    if (cleanPhoneNumber.isEmpty) {
      throw StateError('Mobile number is required.');
    }
    if (experienceYears < 0) {
      throw StateError('Years of experience cannot be negative.');
    }
    if (cleanWorkingDays.isEmpty || cleanWorkingHours.isEmpty) {
      throw StateError('Working days and hours are required.');
    }
    if (cleanLocationId.isEmpty) {
      throw StateError('Please select a supported town.');
    }
    if (![5, 10, 15, 20, 30].contains(serviceRadiusKm)) {
      throw StateError('Please select a valid service radius.');
    }

    final frontDocument = File(nationalIdFrontPath);
    final backDocument = File(nationalIdBackPath);

    if (!await frontDocument.exists() || !await backDocument.exists()) {
      throw StateError('Both National ID images are required.');
    }

    final authenticatedUser = _authService.currentUser;
    if (authenticatedUser == null) {
      throw StateError('Create or sign in to your account before continuing.');
    }

    var userProfile = await _authService.requireActiveUserProfile(
      authenticatedUser.uid,
    );

    if (userProfile.email.trim().isEmpty) {
      throw StateError('Email address is required.');
    }

    if (!userProfile.isProvider) {
      throw StateError('This account is not registered as a provider.');
    }

    String? profileImageStoragePath;
    final cleanProfileImageLocalPath = profileImageLocalPath?.trim();

    if (cleanProfileImageLocalPath != null &&
        cleanProfileImageLocalPath.isNotEmpty) {
      final profileImageFile = File(cleanProfileImageLocalPath);
      if (!await profileImageFile.exists()) {
        throw StateError('The selected profile image could not be found.');
      }

      final profileExtension = _supportedImageExtension(
        cleanProfileImageLocalPath,
      );
      final providerId = userProfile.id;
      profileImageStoragePath = await _storageService.uploadFile(
        file: profileImageFile,
        storagePath: 'providers/$providerId/profile.$profileExtension',
        contentType: _contentType(profileExtension),
        maximumFileSizeBytes: 5 * 1024 * 1024,
      );
    }

    final frontExtension = _supportedImageExtension(nationalIdFrontPath);
    final backExtension = _supportedImageExtension(nationalIdBackPath);
    final verificationRoot = 'verification/${userProfile.id}';

    final frontDocumentStoragePath = await _storageService.uploadFile(
      file: frontDocument,
      storagePath: '$verificationRoot/nic-front.$frontExtension',
      contentType: _contentType(frontExtension),
    );
    final backDocumentStoragePath = await _storageService.uploadFile(
      file: backDocument,
      storagePath: '$verificationRoot/nic-back.$backExtension',
      contentType: _contentType(backExtension),
    );

    final now = DateTime.now();
    final provider = ProviderModel(
      providerId: userProfile.id,
      displayName: userProfile.displayName,
      profileImagePath: profileImageStoragePath,
      bio: _optionalText(bio),
      categoryIds: [cleanCategoryId],
      experienceYears: experienceYears,
      workingDays: cleanWorkingDays,
      workingHours: cleanWorkingHours,
      baseLocation: baseLocation,
      locationId: cleanLocationId,
      serviceRadiusKm: serviceRadiusKm,
      availabilityStatus: 'unavailable',
      verificationStatus: 'pending',
      ratingAverage: 0,
      reviewCount: 0,
      completedJobCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    await _firestoreService.createProviderProfile(
      provider,
      phoneNumber: cleanPhoneNumber,
      frontDocumentPath: frontDocumentStoragePath,
      backDocumentPath: backDocumentStoragePath,
    );

    userProfile = await _authService.requireActiveUserProfile(userProfile.id);
    return userProfile;
  }

  String _supportedImageExtension(String path) {
    final fileName = path.replaceAll(r'\', '/').split('/').last;
    final separatorIndex = fileName.lastIndexOf('.');

    if (separatorIndex == -1 || separatorIndex == fileName.length - 1) {
      return 'jpg';
    }

    final extension = fileName.substring(separatorIndex + 1).toLowerCase();
    const supportedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};

    return supportedExtensions.contains(extension) ? extension : 'jpg';
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  String? _optionalText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}
