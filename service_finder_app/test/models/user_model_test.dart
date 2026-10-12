import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/models/user_model.dart';

void main() {
  final baseData = <String, dynamic>{
    'displayName': 'Customer',
    'email': 'customer@example.com',
    'role': 'customer',
    'accountStatus': 'active',
    'createdAt': Timestamp.fromDate(DateTime(2026)),
  };

  test('older customer profiles load without a saved location', () {
    final user = UserModel.fromMap(documentId: 'customer', data: baseData);
    expect(user.savedLocation, isNull);
    expect(user.locationName, isNull);
    expect(user.toFirestore().containsKey('savedLocation'), isFalse);
  });

  test('saved customer location survives a Firestore round trip', () {
    final user = UserModel.fromMap(
      documentId: 'customer',
      data: {
        ...baseData,
        'savedLocation': const GeoPoint(6.9271, 79.8612),
        'locationName': ' Colombo ',
      },
    );
    final restored = UserModel.fromMap(
      documentId: user.id,
      data: user.toFirestore(),
    );
    expect(restored.savedLocation?.latitude, 6.9271);
    expect(restored.savedLocation?.longitude, 79.8612);
    expect(restored.locationName, 'Colombo');
  });

  test('invalid optional location does not prevent loading the account', () {
    final user = UserModel.fromMap(
      documentId: 'customer',
      data: {...baseData, 'savedLocation': 'invalid', 'locationName': ' '},
    );
    expect(user.savedLocation, isNull);
    expect(user.locationName, isNull);
    expect(user.isActive, isTrue);
  });
}
