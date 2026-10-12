import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/features/provider/provider_profile_status_controller.dart';
import 'package:service_finder_app/features/provider/provider_status_section.dart';
import 'package:service_finder_app/models/provider_model.dart';
import 'package:service_finder_app/widgets/profile_settings.dart';

ProviderModel profile({
  String verification = 'pending',
  String availability = 'unavailable',
}) => ProviderModel(
  providerId: 'provider',
  displayName: 'Provider',
  categoryIds: ['plumber'],
  verificationStatus: verification,
  availabilityStatus: availability,
  ratingAverage: 0,
  reviewCount: 0,
  completedJobCount: 0,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  test('a late initial fetch cannot overwrite newer live status', () async {
    final stream = StreamController<ProviderModel?>();
    final controller = ProviderProfileStatusController(stream.stream);
    stream.add(profile(verification: 'verified', availability: 'available'));
    await Future<void>.delayed(Duration.zero);
    controller.seed(profile());
    expect(controller.profile?.verificationStatus, 'verified');
    expect(controller.profile?.availabilityStatus, 'available');
    controller.dispose();
    await stream.close();
  });

  testWidgets(
    'cached status displays while awaiting live data and survives scroll disposal',
    (tester) async {
      var subscriptions = 0;
      final stream = StreamController<ProviderModel?>.broadcast(
        onListen: () => subscriptions++,
      );
      final controller = ProviderProfileStatusController(stream.stream)
        ..seed(profile());
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileSettingsView(
            name: 'Provider',
            email: 'provider@example.com',
            role: 'Service Provider',
            onLogout: () {},
            accountRows: const [SizedBox(height: 900)],
            professionalRows: [ProviderStatusSection(controller: controller)],
          ),
        ),
      );
      await tester.scrollUntilVisible(find.text('Verification'), 300);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Move the lazy status row out of the viewport before sending an update.
      await tester.scrollUntilVisible(find.text('Provider'), -300);
      stream.add(profile(verification: 'verified', availability: 'available'));
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Verification'), 300);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(subscriptions, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      expect(stream.hasListener, isFalse);
      await stream.close();
    },
  );

  testWidgets('stream failure retains cached status and retry reconnects', (
    tester,
  ) async {
    var subscriptions = 0;
    final stream = StreamController<ProviderModel?>.broadcast(
      onListen: () => subscriptions++,
    );
    final controller = ProviderProfileStatusController(stream.stream)
      ..seed(profile());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProviderStatusSection(controller: controller)),
      ),
    );
    stream.addError(StateError('Offline'));
    await tester.pump();
    expect(find.text('Pending'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.runAsync(() async {
      await tester.tap(find.text('Could not refresh status. Try again'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(subscriptions, 2);
    await tester.runAsync(() async {
      stream.add(profile(verification: 'verified'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(find.text('Verified'), findsOneWidget);
    expect(controller.hasError, isFalse);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await tester.runAsync(stream.close);
  });

  testWidgets(
    'missing provider profile is unavailable rather than loading indefinitely',
    (tester) async {
      final stream = StreamController<ProviderModel?>();
      final controller = ProviderProfileStatusController(stream.stream);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProviderStatusSection(controller: controller)),
        ),
      );
      stream.add(null);
      await tester.pump();
      expect(find.text('Status unavailable'), findsNWidgets(2));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await tester.runAsync(stream.close);
    },
  );
}
