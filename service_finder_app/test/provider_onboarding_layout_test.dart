import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/features/provider/provider_onboarding/provider_onboarding_layout.dart';

void main() {
  testWidgets('short onboarding form moves up above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          resizeToAvoidBottomInset: true,
          body: ProviderOnboardingBody(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ProviderOnboardingHeroText(
                  segments: [
                    ProviderOnboardingHeroSegment('Create'),
                    ProviderOnboardingHeroSegment('your'),
                    ProviderOnboardingHeroSegment('provider', muted: true),
                    ProviderOnboardingHeroSegment('profile'),
                  ],
                ),
                const SizedBox(height: 32),
                const TextField(),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () {}, child: const Text('Continue')),
              ],
            ),
          ),
        ),
      ),
    );

    final before = tester.getTopLeft(find.byType(TextField)).dy;
    await tester.enterText(find.byType(TextField), 'Alex');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byType(TextField)).dy, lessThan(before));
    expect(tester.getBottomLeft(find.byType(TextField)).dy, lessThan(544));
    expect(tester.getBottomLeft(find.byType(ElevatedButton)).dy, lessThan(544));
    expect(find.text('Alex'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long onboarding content scrolls above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderOnboardingBody(
            child: Column(
              children: [
                const ProviderOnboardingHeroText(
                  segments: [
                    ProviderOnboardingHeroSegment('Tell'),
                    ProviderOnboardingHeroSegment('customers'),
                    ProviderOnboardingHeroSegment('about', muted: true),
                    ProviderOnboardingHeroSegment('yourself'),
                  ],
                ),
                const SizedBox(height: 700),
                const TextField(),
                ElevatedButton(onPressed: () {}, child: const Text('Continue')),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.byType(ElevatedButton)).dy,
      lessThanOrEqualTo(544),
    );
    expect(tester.takeException(), isNull);
  });
}
