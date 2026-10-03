import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/models/service_request_model.dart';

void main() {
  test(
    'reads and preserves the customer name without requiring it on old requests',
    () {
      final request = ServiceRequestModel.fromFirestore('id', {
        'customerName': '  Amal Perera  ',
      });
      expect(request.customerName, 'Amal Perera');
      expect(request.toFirestore()['customerName'], 'Amal Perera');
      final oldRequest = ServiceRequestModel.fromFirestore('old', {});
      expect(oldRequest.customerName, isNull);
      expect(oldRequest.toFirestore().containsKey('customerName'), isFalse);
    },
  );

  test('only an active sent quotation is awaiting customer approval', () {
    for (final requestStatus in [
      'submitted',
      'quotation_received',
      'confirmed',
      'in_progress',
      'completed',
      'cancelled',
      'provider_rejected',
    ]) {
      for (final quotationStatus in [
        'pending',
        'sent',
        'accepted',
        'rejected',
        'expired',
      ]) {
        final request = ServiceRequestModel.fromFirestore('id', {
          'requestStatus': requestStatus,
          'quotationStatus': quotationStatus,
        });
        expect(
          request.isAwaitingQuotationApproval,
          requestStatus == 'quotation_received' && quotationStatus == 'sent',
        );
      }
    }
  });

  test('only submitted requests without a pending approval can be quoted', () {
    for (final status in [
      'submitted',
      'quotation_received',
      'confirmed',
      'in_progress',
      'completed',
      'cancelled',
      'provider_rejected',
    ]) {
      for (final quoteStatus in [
        'pending',
        'sent',
        'accepted',
        'rejected',
        'expired',
      ]) {
        final request = ServiceRequestModel.fromFirestore('id', {
          'requestStatus': status,
          'quotationStatus': quoteStatus,
        });
        expect(
          request.canReceiveQuotation,
          status == 'submitted' &&
              ['pending', 'rejected', 'expired'].contains(quoteStatus),
        );
      }
    }
  });

  test(
    'handles unresolved server timestamps and absent optional visit fields',
    () {
      final request = ServiceRequestModel.fromFirestore('id', {
        'createdAt': null,
        'updatedAt': null,
      });
      expect(request.createdAt.millisecondsSinceEpoch, 0);
      expect(request.updatedAt.millisecondsSinceEpoch, 0);
      expect(request.preferredDate, isNull);
      expect(request.preferredTime, isNull);
      expect(request.imagePaths, isNull);
      // Reading optional fields must not add fields to existing request writes.
      expect(request.toFirestore().containsKey('preferredDate'), isFalse);
    },
  );

  test('reads available visit details and uploaded images', () {
    final date = DateTime(2026, 10, 10);
    final request = ServiceRequestModel.fromFirestore('id', {
      'preferredDate': Timestamp.fromDate(date),
      'preferredTime': '10:30 AM',
      'imagePaths': ['serviceRequests/id/photo.jpg'],
      'serviceLocation': {
        'point': const GeoPoint(6.9, 79.8),
        'addressText': 'Colombo',
      },
    });
    expect(request.preferredDate, date);
    expect(request.preferredTime, '10:30 AM');
    expect(request.imagePaths, ['serviceRequests/id/photo.jpg']);
    expect(request.addressText, 'Colombo');
  });
}
