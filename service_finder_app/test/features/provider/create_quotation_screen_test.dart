import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/features/provider/create_quotation_screen.dart';
import 'package:service_finder_app/models/service_request_model.dart';

ServiceRequestModel request() => ServiceRequestModel(
  requestId: 'request-1',
  customerId: 'customer-1',
  providerId: 'provider-1',
  categoryId: 'plumber',
  title: 'Leaking kitchen tap',
  description: 'The tap leaks.',
  servicePoint: const GeoPoint(6.9, 79.8),
  addressText: 'Colombo',
  requestStatus: 'submitted',
  quotationStatus: 'pending',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  Future<void> openForm(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: CreateQuotationScreen(request: request())),
    );
  }

  testWidgets('blocks invalid monetary values before sending', (tester) async {
    await openForm(tester);
    final charge = find.byType(TextFormField).at(0);
    for (final value in ['', '0', '-1', 'NaN', 'Infinity', '1.001']) {
      await tester.enterText(charge, value);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send quotation'));
      await tester.pump();
      expect(
        find.text('Enter a charge greater than 0 (up to 2 decimals).'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
    }
    await tester.enterText(charge, '5000');
    await tester.enterText(find.byType(TextFormField).at(1), '-10');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send quotation'));
    await tester.pump();
    expect(
      find.text('Enter a valid fee (0 or more, up to 2 decimals).'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows the total and preserves the form when reviewing confirmation',
    (tester) async {
      await openForm(tester);
      await tester.enterText(find.byType(TextFormField).at(0), '5000.50');
      await tester.enterText(find.byType(TextFormField).at(1), '500');
      await tester.pump();
      expect(find.text('Rs. 5500.50'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send quotation'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('Send an estimated total of Rs. 5500.50'),
        findsOneWidget,
      );
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('5000.50'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Send quotation'),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
