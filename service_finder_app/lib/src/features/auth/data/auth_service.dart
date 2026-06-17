import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream to track auth state changes
  Stream<User?> get userStream => _auth.authStateChanges();

  // Register with Email and Password + Save Role to Firestore
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Save user role data to Firestore collection
        await _db.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'role': role.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return credential;
    } catch (e) {
      print("Registration Error: ${e.toString()}");
      rethrow;
    }
  }

  // Login with Email and Password
  Future<UserCredential?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Login Error: ${e.toString()}");
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Sign Out Error: ${e.toString()}");
    }
  }
}