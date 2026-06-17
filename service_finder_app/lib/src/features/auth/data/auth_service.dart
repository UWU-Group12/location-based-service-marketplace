import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // 👉 Required for debugPrint
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
      debugPrint("Registration Error: ${e.toString()}"); // ✅ Changed to debugPrint
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
      debugPrint("Login Error: ${e.toString()}"); // ✅ Changed to debugPrint
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Sign Out Error: ${e.toString()}"); // ✅ Changed to debugPrint
    }
  }
}