import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/core/app_colors.dart';
import 'package:service_finder_app/widgets/profile_settings.dart';

Widget profile({
  VoidCallback? onEdit,
  VoidCallback? onLogout,
  bool provider = false,
}) => MaterialApp(
  theme: ThemeData(scaffoldBackgroundColor: AppColors.background),
  home: ProfileSettingsView(
    name: 'Sample Customer',
    email: 'customer@example.com',
    role: provider ? 'Service Provider' : 'Customer',
    onLogout: onLogout ?? () {},
    accountRows: [
      ProfileSettingsRow(
        icon: Icons.person_outline,
        title: 'Personal information',
        onTap: onEdit ?? () {},
      ),
    ],
    professionalRows: provider
        ? const [
            ProfileSettingsRow(
              icon: Icons.verified_outlined,
              title: 'Verification status',
              value: 'Pending',
            ),
          ]
        : const [],
  ),
);

void main() {
  testWidgets(
    'profile card is display-only and personal information opens editing',
    (tester) async {
      var edits = 0;
      await tester.pumpWidget(profile(onEdit: () => edits++));
      await tester.tap(find.text('Sample Customer'));
      expect(edits, 0);
      final header = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Sample Customer'),
          matching: find.byType(ListTile),
        ),
      );
      expect(header.onTap, isNull);
      expect(header.trailing, isNull);
      await tester.tap(find.text('Personal information'));
      expect(edits, 1);
      expect(find.text('Notifications'), findsNothing);
      expect(find.text('Dark mode'), findsNothing);
      expect(find.text('Professional details'), findsNothing);
    },
  );

  testWidgets('language opens English-only screen and returns to profile', (
    tester,
  ) async {
    await tester.pumpWidget(profile(provider: true));
    expect(find.text('Verification status'), findsOneWidget);
    await tester.ensureVisible(find.text('Language'));
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Current language'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
  });

  testWidgets(
    'small screens and large text can scroll to logout without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var loggedOut = false;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: ProfileSettingsView(
            name: 'A Customer With A Long Full Name',
            email: 'customer@example.com',
            role: 'Customer',
            onLogout: () => loggedOut = true,
            accountRows: const [
              ProfileSettingsRow(
                icon: Icons.person_outline,
                title: 'Personal information',
              ),
            ],
          ),
        ),
      );
      await tester.scrollUntilVisible(find.text('Log Out'), 300);
      await tester.tap(find.text('Log Out'));
      expect(loggedOut, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
