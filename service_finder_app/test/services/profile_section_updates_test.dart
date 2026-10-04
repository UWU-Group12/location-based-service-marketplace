import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/services/firestore_service.dart';

/// In-memory documents let these tests verify that section saves preserve
/// unrelated fields, without initializing Firebase or contacting a server.
class _MemoryFirestore extends Fake implements FirebaseFirestore {
  final documents = <String, Map<String, dynamic>>{};

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this, path);

  @override
  WriteBatch batch() => _Batch();
}

// SDK query types are sealed for application code; this test-only fake records writes.
// ignore: subtype_of_sealed_class
class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final _MemoryFirestore database;
  final String collectionPath;
  _Collection(this.database, this.collectionPath);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Document(database, '$collectionPath/$path');
}

// Test-only reference that applies writes to the in-memory documents above.
// ignore: subtype_of_sealed_class
class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final _MemoryFirestore database;
  final String documentPath;
  _Document(this.database, this.documentPath);

  @override
  Future<void> update(Map<Object, Object?> data) async {
    database.documents[documentPath]!.addAll(Map<String, dynamic>.from(data));
  }
}

class _Batch extends Fake implements WriteBatch {
  final _writes = <Future<void> Function()>[];

  @override
  void update(DocumentReference document, Map<Object, Object?> data) {
    _writes.add(() => document.update(data));
  }

  @override
  Future<void> commit() async {
    for (final write in _writes) {
      await write();
    }
  }
}

void main() {
  late _MemoryFirestore database;
  late FirestoreService service;

  setUp(() {
    database = _MemoryFirestore();
    service = FirestoreService(firestore: database);
    database.documents['users/user'] = {
      'displayName': 'Original name',
      'phoneNumber': '0771234567',
      'photoPath': 'photos/original.jpg',
      'savedLocation': const GeoPoint(6.9, 79.8),
      'locationName': 'Colombo',
      'role': 'provider',
    };
    database.documents['providerProfiles/user'] = {
      'displayName': 'Original name',
      'bio': 'Original bio',
      'profileImagePath': 'photos/original.jpg',
      'baseLocation': const GeoPoint(6.9, 79.8),
      'serviceRadiusKm': 10.0,
      'verificationStatus': 'verified',
      'categoryIds': ['plumber'],
    };
  });

  test(
    'provider personal information can save with no base location and preserves professional data',
    () async {
      database.documents['providerProfiles/user']!.remove('baseLocation');
      final original = Map<String, dynamic>.from(
        database.documents['providerProfiles/user']!,
      );
      await service.updateProviderPersonalInformation(
        providerId: 'user',
        displayName: ' New name ',
        phoneNumber: '0777654321',
      );
      final provider = database.documents['providerProfiles/user']!;
      expect(provider['displayName'], 'New name');
      expect(database.documents['users/user']!['displayName'], 'New name');
      expect(database.documents['users/user']!['phoneNumber'], '0777654321');
      expect(provider.containsKey('baseLocation'), isFalse);
      for (final key in [
        'bio',
        'serviceRadiusKm',
        'verificationStatus',
        'categoryIds',
        'profileImagePath',
      ]) {
        expect(provider[key], original[key]);
      }
    },
  );

  test(
    'service area save preserves personal and professional information',
    () async {
      final originalUser = Map<String, dynamic>.from(
        database.documents['users/user']!,
      );
      await service.updateProviderServiceArea(
        providerId: 'user',
        baseLocation: const GeoPoint(7.3, 80.6),
        serviceRadiusKm: 20,
      );
      final provider = database.documents['providerProfiles/user']!;
      expect(provider['baseLocation'], const GeoPoint(7.3, 80.6));
      expect(provider['serviceRadiusKm'], 20);
      expect(provider['bio'], 'Original bio');
      expect(provider['displayName'], 'Original name');
      expect(provider['verificationStatus'], 'verified');
      expect(database.documents['users/user'], originalUser);
    },
  );

  test(
    'professional bio save preserves location, radius, and personal information',
    () async {
      await service.updateProviderProfessionalInformation(
        providerId: 'user',
        bio: ' Updated bio ',
      );
      final provider = database.documents['providerProfiles/user']!;
      expect(provider['bio'], 'Updated bio');
      expect(provider['baseLocation'], const GeoPoint(6.9, 79.8));
      expect(provider['serviceRadiusKm'], 10);
      expect(provider['displayName'], 'Original name');
      expect(provider['verificationStatus'], 'verified');
      expect(
        database.documents['users/user']!.containsKey('updatedAt'),
        isFalse,
      );
    },
  );

  test('customer location save preserves name, phone, and photo', () async {
    await service.updateCustomerLocation(
      userId: 'user',
      savedLocation: const GeoPoint(7.3, 80.6),
      locationName: ' Kandy ',
    );
    final customer = database.documents['users/user']!;
    expect(customer['savedLocation'], const GeoPoint(7.3, 80.6));
    expect(customer['locationName'], 'Kandy');
    expect(customer['displayName'], 'Original name');
    expect(customer['phoneNumber'], '0771234567');
    expect(customer['photoPath'], 'photos/original.jpg');
  });
}
