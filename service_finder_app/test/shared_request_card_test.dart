import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/features/customer/customer_requests_screen.dart';
import 'package:service_finder_app/models/service_request_model.dart';
import 'package:service_finder_app/widgets/request_card.dart';

ServiceRequestModel job({
  String id = 'job-1',
  String status = 'completed',
  String? title,
}) => ServiceRequestModel(
  requestId: id,
  customerId: 'customer',
  customerName: 'Jane Customer',
  providerId: 'provider',
  categoryId: 'plumber',
  title: title ?? 'Repair kitchen tap',
  description: 'Long description not shown in cards',
  servicePoint: const GeoPoint(6.9, 79.8),
  addressText: 'Colombo 05',
  requestStatus: status,
  quotationStatus: 'accepted',
  finalAmount: 5500,
  createdAt: DateTime(2026, 8, 4),
  updatedAt: DateTime(2026, 8, 6),
);

void main() {
  testWidgets(
    'active and finished jobs show readable statuses, totals and updated dates',
    (tester) async {
      for (final status in {
        'confirmed': 'Confirmed',
        'in_progress': 'In progress',
        'completed': 'Completed',
      }.entries) {
        final data = job(status: status.key);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RequestCard(request: data, onTap: () {}),
            ),
          ),
        );
        expect(find.text(status.value), findsOneWidget);
        expect(find.text('Rs. 5,500.00'), findsOneWidget);
        expect(find.text('Jane Customer'), findsOneWidget);
        expect(find.text(data.description), findsNothing);
        final dates = MaterialLocalizations.of(
          tester.element(find.byType(RequestCard)),
        );
        expect(
          find.text(dates.formatShortMonthDay(data.updatedAt)),
          findsOneWidget,
        );
        expect(
          find.byTooltip(
            'Job updated on ${dates.formatMediumDate(data.updatedAt)}',
          ),
          findsOneWidget,
        );
        expect(find.text('Rate'), findsNothing);
      }
    },
  );

  testWidgets(
    'black top-right rating button opens rating without opening request details',
    (tester) async {
      var ratings = 0;
      var details = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: RequestCard.customer(
                request: job(),
                providerName: 'Alex Provider',
                onTap: () => details++,
                onRate: () => ratings++,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Alex Provider'), findsOneWidget);
      expect(find.text('Jane Customer'), findsNothing);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style?.backgroundColor?.resolve({}), Colors.black);
      expect(button.style?.foregroundColor?.resolve({}), Colors.white);
      expect(
        tester.getTopLeft(find.text('Rate')).dx,
        greaterThan(tester.getTopLeft(find.text('Completed')).dx),
      );
      expect(
        tester.getTopLeft(find.text('Rate')).dy,
        lessThan(tester.getTopLeft(find.text('Repair kitchen tap')).dy),
      );
      await tester.tap(find.text('Rate'));
      expect(ratings, 1);
      expect(details, 0);
      await tester.tap(find.text('Repair kitchen tap'));
      expect(details, 1);
    },
  );

  testWidgets('unfinished customer requests never show a rating button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RequestCard.customer(
            request: job(status: 'in_progress'),
            providerName: 'Alex Provider',
            onTap: () {},
            onRate: () {},
          ),
        ),
      ),
    );
    expect(find.text('Rate'), findsNothing);
    expect(find.text('In progress'), findsOneWidget);
  });

  testWidgets(
    'completed customer cards fit long names and rating actions at large text sizes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var rated = 0;
      for (final scale in [1.0, 2.0, 3.0]) {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: RequestCard.customer(
                  request: job(
                    title:
                        'Repair the kitchen tap and inspect the plumbing throughout the whole building',
                  ),
                  providerName: 'A Provider With A Very Long Full Name',
                  onTap: () {},
                  onRate: () => rated++,
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Rate'));
      }
      expect(rated, 3);
    },
  );

  testWidgets(
    'review loading, submission, and repeated stream events preserve rating eligibility',
    (tester) async {
      final requests = StreamController<List<ServiceRequestModel>>.broadcast();
      final reviews = StreamController<Set<String>>.broadcast();
      final result = Completer<bool?>();
      var namesLoaded = 0;
      final ratedIds = <String>[];
      final openedIds = <String>[];
      await tester.binding.setSurfaceSize(const Size(500, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: CustomerRequestsScreen(
            showServices: true,
            requestsStream: requests.stream,
            reviewedRequestIdsStream: reviews.stream,
            loadProviderName: (id) async {
              namesLoaded++;
              return 'Alex Provider';
            },
            onRate: (id) {
              ratedIds.add(id);
              return result.future;
            },
            onOpenRequest: openedIds.add,
          ),
        ),
      );
      requests.add([
        job(),
        job(id: 'active-job', status: 'in_progress', title: 'Active job'),
      ]);
      await tester.pumpAndSettle();
      // The in-progress job is on the Active tab; the completed one on Finished.
      expect(find.text('Active job'), findsOneWidget);
      expect(find.text('Alex Provider'), findsOneWidget);
      await tester.tap(find.text('Finished'));
      await tester.pumpAndSettle();
      expect(find.text('Rate'), findsNothing);
      expect(find.text('Alex Provider'), findsOneWidget);
      expect(namesLoaded, 1);
      reviews.add({});
      await tester.pumpAndSettle();
      expect(find.text('Rate'), findsOneWidget);
      await tester.tap(find.text('Rate'));
      expect(ratedIds, ['job-1']);
      expect(openedIds, isEmpty);
      result.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Rate'), findsNothing);
      // A temporarily stale backend event must not bring back the Rate action.
      reviews.add({});
      requests.add([
        job(),
        job(id: 'active-job', status: 'in_progress', title: 'Active job'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Rate'), findsNothing);
      expect(namesLoaded, 1);
      await tester.tap(find.text('Repair kitchen tap'));
      expect(openedIds, ['job-1']);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await requests.close();
        await reviews.close();
      });
    },
  );

  testWidgets(
    'reviewed jobs and review lookup failures hide rating; cancellation permits retry',
    (tester) async {
      final requests = StreamController<List<ServiceRequestModel>>.broadcast();
      final reviews = StreamController<Set<String>>.broadcast();
      await tester.pumpWidget(
        MaterialApp(
          home: CustomerRequestsScreen(
            showServices: true,
            requestsStream: requests.stream,
            reviewedRequestIdsStream: reviews.stream,
            loadProviderName: (_) async => 'Alex Provider',
            onRate: (_) async => false,
          ),
        ),
      );
      requests.add([job()]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finished'));
      await tester.pumpAndSettle();
      reviews.add({'job-1'});
      await tester.pumpAndSettle();
      expect(find.text('Rate'), findsNothing);
      reviews.add({});
      await tester.pumpAndSettle();
      expect(find.text('Rate'), findsOneWidget);
      await tester.tap(find.text('Rate'));
      await tester.pumpAndSettle();
      expect(find.text('Rate'), findsOneWidget);
      reviews.addError(StateError('Offline'));
      await tester.pumpAndSettle();
      expect(find.text('Rate'), findsNothing);
      expect(find.text('Repair kitchen tap'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await requests.close();
        await reviews.close();
      });
    },
  );
}
