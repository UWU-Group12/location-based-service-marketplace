enum UserRole { customer, provider, admin }

class AppUser {
  final String uid;
  final String email;
  final UserRole role;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
  });

  // Convert Firestore Document data to our AppUser Model
  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      uid: documentId,
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
            (e) => e.name == map['role'],
        orElse: () => UserRole.customer, // Default role
      ),
    );
  }

  // Convert our AppUser Model data to a Map to save into Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role.name,
    };
  }
}
