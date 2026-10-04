import '../models/personal_information_update.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'storage_service.dart';

class ProfileEditService {
  Future<void> savePersonalInformation(
    UserRole role,
    PersonalInformationUpdate update,
  ) async {
    final auth = AuthService();
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('Please sign in to edit your profile.');
    String? photoPath;
    String? photoUrl;
    if (update.image != null) {
      final storage = StorageService();
      photoPath = await storage.uploadProfileImage(
        file: update.image!,
        userFolder: '${role == UserRole.provider ? 'providers' : 'users'}/$uid',
      );
      photoUrl = await storage.getDownloadUrl(photoPath);
    }
    final firestore = FirestoreService();
    if (role == UserRole.provider) {
      await firestore.updateProviderPersonalInformation(
        providerId: uid,
        displayName: update.name,
        phoneNumber: update.phone,
        profileImagePath: photoPath,
        clearPhoto: update.clearPhoto,
      );
    } else {
      await firestore.updateCustomerProfile(
        userId: uid,
        displayName: update.name,
        phoneNumber: update.phone,
        photoPath: photoPath,
        clearPhoto: update.clearPhoto,
      );
    }
    await auth.updateAuthProfile(
      displayName: update.name,
      photoUrl: photoUrl,
      clearPhoto: update.clearPhoto,
    );
  }
}
