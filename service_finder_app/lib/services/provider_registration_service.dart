import '../models/provider_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

class ProviderRegistrationService {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  ProviderRegistrationService({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService();

  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String bio,
    required String categoryId,
  }) async {
    if (categoryId.trim().isEmpty) {
      throw StateError('Please select a service category.');
    }

    var userProfile = await _findOrCreateUserProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
    );

    if (!userProfile.isProvider) {
      throw StateError('This account is not registered as a provider.');
    }

    final now = DateTime.now();
    final provider = ProviderModel(
      providerId: userProfile.id,
      displayName: userProfile.displayName,
      bio: _optionalText(bio),
      categoryIds: [categoryId],
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
      phoneNumber: _optionalText(phoneNumber),
    );

    userProfile = await _authService.requireActiveUserProfile(userProfile.id);
    return userProfile;
  }

  Future<UserModel> _findOrCreateUserProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final authenticatedUser = _authService.currentUser;

    if (authenticatedUser != null) {
      final existingProfile = await _authService.getUserProfile(
        authenticatedUser.uid,
      );

      if (existingProfile != null) {
        return existingProfile;
      }

      return _authService.createCurrentUserProfile(UserRole.provider);
    }

    final displayName = '$firstName $lastName'.trim();
    if (displayName.isEmpty || email.trim().isEmpty || password.isEmpty) {
      throw StateError('Name, email, and password are required.');
    }

    final result = await _authService
        .registerWithEmail(email.trim(), password, {
          'displayName': displayName,
          'email': email.trim(),
          if (phoneNumber.trim().isNotEmpty) 'phoneNumber': phoneNumber.trim(),
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

  String? _optionalText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}
