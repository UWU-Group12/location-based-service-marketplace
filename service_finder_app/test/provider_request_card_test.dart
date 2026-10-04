import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/models/quotation_model.dart';
import 'package:service_finder_app/models/service_request_model.dart';
import 'package:service_finder_app/widgets/provider_request_card.dart';

ServiceRequestModel request({
  String? name = 'Jane Customer',
  String title = 'Leaking kitchen tap',
  String location = 'Colombo 05',
  DateTime? createdAt,
}) => ServiceRequestModel(
  requestId: 'request-1',
  customerId: 'customer-1',
  customerName: name,
  providerId: 'provider-1',
  categoryId: 'plumber',
  title: title,
  description: 'The kitchen tap leaks continuously and needs repairing.',
  servicePoint: const GeoPoint(6.9, 79.8),
  addressText: location,
  requestStatus: 'submitted',
  quotationStatus: 'pending',
  createdAt: createdAt ?? DateTime(2026, 8, 4),
  updatedAt: DateTime(2026, 8, 4),
  preferredDate: DateTime(2026, 8, 12),
);

QuotationModel quotation({double amount = 5500, DateTime? createdAt}) =>
    QuotationModel(
      quotationId: 'quote-1',
      requestId: 'request-1',
      customerId: 'customer-1',
      providerId: 'provider-1',
      serviceCharge: amount,
      estimatedTotal: amount,
      status: 'sent',
      createdAt: createdAt ?? DateTime(2026, 8, 5),
      updatedAt: DateTime(2026, 8, 5),
      availableAt: DateTime(2026, 8, 15),
    );

Future<void> showCard(
  WidgetTester tester,
  Widget card, {
  double textScale = 1,
}) => tester.pumpWidget(
  MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: card,
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'received summary omits description and opens details from the card',
    (tester) async {
      var taps = 0;
      final data = request();
      await showCard(
        tester,
        ProviderRequestCard.received(request: data, onTap: () => taps++),
      );
      expect(find.text('Received'), findsOneWidget);
      expect(find.text('Leaking kitchen tap'), findsOneWidget);
      expect(find.text('Colombo 05'), findsOneWidget);
      expect(find.text('Jane Customer'), findsOneWidget);
      expect(find.text('JC'), findsOneWidget);
      expect(find.text(data.description), findsNothing);
      expect(find.text('request-1'), findsNothing);
      final context = tester.element(find.byType(ProviderRequestCard));
      final dates = MaterialLocalizations.of(context);
      expect(
        find.text(dates.formatShortMonthDay(data.createdAt)),
        findsOneWidget,
      );
      expect(
        find.text(dates.formatShortMonthDay(data.preferredDate!)),
        findsNothing,
      );
      await tester.tap(find.text('Leaking kitchen tap'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sent quotation uses its total and sent date, rather than appointment date',
    (tester) async {
      var opened = false;
      final quote = quotation();
      await showCard(
        tester,
        ProviderRequestCard.sent(
          request: request(),
          quotation: quote,
          onTap: () => opened = true,
        ),
      );
      expect(find.text('Awaiting approval'), findsOneWidget);
      expect(find.text('Rs. 5,500.00'), findsOneWidget);
      final context = tester.element(find.byType(ProviderRequestCard));
      final dates = MaterialLocalizations.of(context);
      expect(
        find.text(dates.formatShortMonthDay(quote.createdAt)),
        findsOneWidget,
      );
      expect(
        find.text(dates.formatShortMonthDay(quote.availableAt!)),
        findsNothing,
      );
      expect(
        find.byTooltip(
          'Quotation sent on ${dates.formatMediumDate(quote.createdAt)}',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Rs. 5,500.00'));
      expect(opened, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'missing customer, location, request and timestamps show useful fallbacks',
    (tester) async {
      final unknownDate = DateTime.fromMillisecondsSinceEpoch(0);
      await showCard(
        tester,
        ProviderRequestCard.received(
          request: request(name: ' ', location: ' ', createdAt: unknownDate),
          onTap: () {},
        ),
      );
      expect(find.text('Name unavailable'), findsOneWidget);
      expect(find.text('Location unavailable'), findsOneWidget);
      expect(find.text('Date unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      await showCard(
        tester,
        ProviderRequestCard.sent(
          request: null,
          quotation: quotation(createdAt: unknownDate),
          onTap: () {},
        ),
      );
      expect(find.text('Request unavailable'), findsOneWidget);
      expect(find.text('Name unavailable'), findsOneWidget);
      expect(find.text('Location unavailable'), findsOneWidget);
      expect(find.text('Date unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('long content stays tappable on narrow screens with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = request(
      name: 'A Customer With A Very Long Full Name',
      title:
          'Repair the leaking kitchen tap and inspect the plumbing throughout the entire house',
      location:
          'A very long street address in Colombo with additional apartment and landmark details',
    );
    var taps = 0;
    for (final scale in [1.0, 2.0, 3.0]) {
      for (final card in [
        ProviderRequestCard.received(request: data, onTap: () => taps++),
        ProviderRequestCard.sent(
          request: data,
          quotation: quotation(amount: 1234567.89),
          onTap: () => taps++,
        ),
      ]) {
        await showCard(tester, card, textScale: scale);
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(data.title));
      }
    }
    expect(taps, 6);
  });
}
