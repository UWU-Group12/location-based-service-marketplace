import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, provider }

enum AccountStatus { active, suspended, disabled }

class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? phoneNumber;
  final String? photoPath;
  final UserRole role;
  final AccountStatus accountStatus;
  final bool profileCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.phoneNumber,
    this.photoPath,
    required this.role,
    required this.accountStatus,
    required this.profileCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCustomer => role == UserRole.customer;

  bool get isProvider => role == UserRole.provider;

  bool get isActive => accountStatus == AccountStatus.active;

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('User document ${document.id} does not contain data.');
    }

    return UserModel.fromMap(documentId: document.id, data: data);
  }

  factory UserModel.fromMap({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    final createdAt = _readOptionalDate(data['createdAt']);
    final updatedAt = _readOptionalDate(data['updatedAt']);

    // Server timestamps can be null briefly while a Firestore write is pending.
    final resolvedCreatedAt = createdAt ?? updatedAt ?? DateTime.now();
    final resolvedUpdatedAt = updatedAt ?? resolvedCreatedAt;

    return UserModel(
      id: documentId,
      displayName: _readString(data['displayName'], fieldName: 'displayName'),
      email: _readString(data['email'], fieldName: 'email'),
      phoneNumber: _readOptionalString(data['phoneNumber']),
      photoPath: _readOptionalString(data['photoPath']),
      role: _readRole(data['role']),
      accountStatus: _readAccountStatus(data['accountStatus']),
      profileCompleted: data['profileCompleted'] as bool? ?? false,
      createdAt: resolvedCreatedAt,
      updatedAt: resolvedUpdatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName.trim(),
      'email': email.trim(),
      if (phoneNumber != null) 'phoneNumber': phoneNumber!.trim(),
      if (photoPath != null) 'photoPath': photoPath!.trim(),
      'role': role.name,
      'accountStatus': accountStatus.name,
      'profileCompleted': profileCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static String _readString(dynamic value, {required String fieldName}) {
    if (value is String) {
      return value.trim();
    }

    throw FormatException('User field "$fieldName" must be a String.');
  }

  static String? _readOptionalString(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      return null;
    }

    final text = value.trim();

    return text.isEmpty ? null : text;
  }

  static UserRole _readRole(dynamic value) {
    final role = value?.toString().trim().toLowerCase();

    switch (role) {
      case 'customer':
        return UserRole.customer;

      case 'provider':
        return UserRole.provider;

      default:
        throw FormatException('Unsupported user role: $value');
    }
  }

  static AccountStatus _readAccountStatus(dynamic value) {
    final status = value?.toString().trim().toLowerCase();

    switch (status) {
      case 'active':
        return AccountStatus.active;

      case 'suspended':
        return AccountStatus.suspended;

      case 'disabled':
        return AccountStatus.disabled;

      default:
        // Missing or unknown status should not automatically
        // give the user active access.
        return AccountStatus.disabled;
    }
  }

  static DateTime? _readOptionalDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
