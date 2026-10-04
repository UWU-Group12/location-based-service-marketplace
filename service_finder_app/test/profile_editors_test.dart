import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/features/customer/personal_information_screen.dart';
import 'package:service_finder_app/features/customer/saved_location_screen.dart';
import 'package:service_finder_app/features/provider/provider_professional_profile_screen.dart';
import 'package:service_finder_app/features/provider/provider_service_area_screen.dart';
import 'package:service_finder_app/models/personal_information_update.dart';

void main() {
  Future<void> openEditor(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => screen),
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'personal information saves without a location or professional fields',
    (tester) async {
      PersonalInformationUpdate? saved;
      await openEditor(
        tester,
        PersonalInformationScreen(
          name: 'Provider',
          phone: '0771234567',
          email: 'provider@example.com',
          requirePhone: true,
          onSave: (update) async {
            saved = update;
          },
        ),
      );
      expect(find.text('Professional bio'), findsNothing);
      expect(find.text('Service radius'), findsNothing);
      expect(find.text('Pick on map'), findsNothing);
      await tester.enterText(
        find.byType(TextFormField).first,
        ' Updated Provider ',
      );
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(saved?.name, 'Updated Provider');
      expect(saved?.phone, '0771234567');
      expect(saved?.clearPhoto, isFalse);
      expect(find.text('Open editor'), findsOneWidget);
    },
  );

  testWidgets(
    'saved location validates independently and has no personal fields',
    (tester) async {
      var saves = 0;
      await openEditor(
        tester,
        SavedLocationScreen(
          onSave: (_, _) async {
            saves++;
          },
        ),
      );
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Service radius'), findsNothing);
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      expect(saves, 0);
      expect(
        find.text('Please choose your location using GPS or the map.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'service area saves radius and location without personal information',
    (tester) async {
      GeoPoint? savedPoint;
      double? savedRadius;
      await openEditor(
        tester,
        ProviderServiceAreaScreen(
          location: const GeoPoint(6.9, 79.8),
          locationName: 'Colombo',
          serviceRadiusKm: 10,
          onSave: (point, radius) async {
            savedPoint = point;
            savedRadius = radius;
          },
        ),
      );
      expect(find.text('Full name'), findsNothing);
      expect(find.text('Professional bio'), findsNothing);
      await tester.tap(find.text('20 km'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(savedPoint, const GeoPoint(6.9, 79.8));
      expect(savedRadius, 20);
      expect(find.text('Open editor'), findsOneWidget);
    },
  );

  testWidgets(
    'professional profile keeps the draft on save failure and can retry',
    (tester) async {
      final firstSave = Completer<void>();
      var calls = 0;
      String? saved;
      await openEditor(
        tester,
        ProviderProfessionalProfileScreen(
          bio: 'Original bio',
          categoryNames: 'Plumbing',
          onSave: (bio) async {
            calls++;
            if (calls == 1) await firstSave.future;
            saved = bio;
          },
        ),
      );
      expect(find.text('Full name'), findsNothing);
      expect(find.text('Service radius'), findsNothing);
      await tester.enterText(find.byType(TextField), ' Updated bio ');
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      firstSave.completeError(StateError('Offline'));
      await tester.pumpAndSettle();
      expect(find.text(' Updated bio '), findsOneWidget);
      expect(
        find.text(
          'Could not save your professional profile. Please try again.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(saved, 'Updated bio');
      expect(calls, 2);
      expect(find.text('Open editor'), findsOneWidget);
    },
  );
}
