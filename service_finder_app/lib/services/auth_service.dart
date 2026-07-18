import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get user => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get hasAuthenticatedUser => _auth.currentUser != null;
  bool get currentUserUsesGoogle {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return false;
    }

    return firebaseUser.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );
  }

  Future<UserCredential> registerWithEmail(
    String email,
    String password,
    Map<String, dynamic> userData,
  ) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user;

    if (user == null) {
      throw StateError('Firebase did not return the registered user.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      ...userData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return result;
  }

  Future<UserCredential> loginWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }

    final googleAuthentication = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuthentication.accessToken,
      idToken: googleAuthentication.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    final firebaseUser = result.user;

    if (firebaseUser == null) {
      throw StateError('Firebase did not return the Google user.');
    }

    return result;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final document = await _firestore.collection('users').doc(userId).get();

    return _userFromDocument(document);
  }

  Future<UserModel?> getUserProfileForCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    return getUserProfile(firebaseUser.uid);
  }

  Stream<UserModel?> watchUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map(_userFromDocument);
  }

  Future<UserModel> requireActiveUserProfile(String userId) async {
    final profile = await getUserProfile(userId);

    if (profile == null) {
      throw StateError('Your account profile was not found.');
    }

    if (!profile.isActive) {
      await signOut();
      throw StateError(
        'This account is ${profile.accountStatus.name}. Please contact support.',
      );
    }

    return profile;
  }

  Future<UserModel> createCurrentUserProfile(UserRole role) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw StateError('The authenticated user was not found.');
    }

    final existingProfile = await getUserProfile(firebaseUser.uid);
    if (existingProfile != null) {
      return existingProfile;
    }

    final email = firebaseUser.email?.trim() ?? '';
    if (email.isEmpty) {
      throw StateError('The authenticated account has no email address.');
    }

    final authenticationName = firebaseUser.displayName?.trim();
    final displayName = authenticationName == null || authenticationName.isEmpty
        ? email.split('@').first
        : authenticationName;

    await _firestore.collection('users').doc(firebaseUser.uid).set({
      'displayName': displayName,
      'email': email,
      'role': role.name,
      'accountStatus': 'active',
      'profileCompleted': role == UserRole.customer,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return requireActiveUserProfile(firebaseUser.uid);
  }

  Future<String?> getUserRole(String userId) async {
    final profile = await getUserProfile(userId);
    return profile?.role.name;
  }

  UserModel? _userFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    if (!document.exists) {
      return null;
    }

    return UserModel.fromFirestore(document);
  }
}
