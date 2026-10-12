import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/models/provider_model.dart';
import 'package:service_finder_app/widgets/featured_provider_carousel.dart';

ProviderModel provider(String id, String name) => ProviderModel(
  providerId: id,
  displayName: name,
  categoryIds: ['plumber', 'electrician'],
  availabilityStatus: 'available',
  verificationStatus: 'verified',
  ratingAverage: 4.5,
  reviewCount: 12,
  completedJobCount: 18,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final providers = [
  provider('provider-1', 'Alex Morgan'),
  provider('provider-2', 'Blair Stone'),
  provider('provider-3', 'Casey Reed'),
];

Widget carouselApp({
  List<ProviderModel>? data,
  bool tickerEnabled = true,
  bool reduceMotion = false,
  ValueChanged<ProviderModel>? onViewDetails,
  Duration interval = const Duration(seconds: 4),
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: TickerMode(
        enabled: tickerEnabled,
        child: FeaturedProviderCarousel(
          providers: data ?? providers,
          interval: interval,
          onViewDetails: onViewDetails ?? (_) {},
        ),
      ),
    ),
  ),
);

Future<void> pumpCarousel(
  WidgetTester tester, {
  List<ProviderModel>? data,
  bool tickerEnabled = true,
  bool reduceMotion = false,
  ValueChanged<ProviderModel>? onViewDetails,
  Duration interval = const Duration(seconds: 4),
}) async {
  await tester.pumpWidget(
    carouselApp(
      data: data,
      tickerEnabled: tickerEnabled,
      reduceMotion: reduceMotion,
      onViewDetails: onViewDetails,
      interval: interval,
    ),
  );
  await tester.pump();
}

Future<void> pumpConstrainedCarousel(
  WidgetTester tester, {
  required double width,
  required double textScale,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FeaturedProviderCarousel(
                providers: [
                  provider('provider-1', 'Alex Morgan'),
                  ProviderModel(
                    providerId: 'provider-2',
                    displayName: 'Blair Stone',
                    categoryIds: [
                      'home_cleaning',
                      'electrical_repair',
                      'garden_maintenance',
                    ],
                    availabilityStatus: 'available',
                    verificationStatus: 'verified',
                    ratingAverage: 4.7,
                    reviewCount: 38,
                    completedJobCount: 92,
                    createdAt: DateTime(2026),
                    updatedAt: DateTime(2026),
                  ),
                ],
                interval: const Duration(seconds: 4),
                onViewDetails: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

List<String> visibleNames(WidgetTester tester) {
  final viewport = tester.getRect(find.byType(PageView));
  return [
    for (final data in providers)
      if (find.text(data.displayName).evaluate().isNotEmpty &&
          tester.getRect(find.text(data.displayName)).overlaps(viewport))
        data.displayName,
  ];
}

Future<void> disposeCarousel(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  testWidgets('shows exactly one provider card in the viewport', (
    tester,
  ) async {
    await pumpCarousel(tester);

    expect(visibleNames(tester), hasLength(1));

    await disposeCarousel(tester);
  });

  testWidgets('paints the soft shadow outside the clipped PageView', (
    tester,
  ) async {
    await pumpCarousel(tester);

    final frameFinder = find.byKey(const ValueKey('featured-provider-frame'));
    expect(frameFinder, findsOneWidget);
    expect(
      find.ancestor(of: find.byType(PageView), matching: frameFinder),
      findsOneWidget,
    );

    final frame = tester.widget<Container>(frameFinder);
    final decoration = frame.decoration! as BoxDecoration;
    expect(decoration.color, Colors.white);
    expect(decoration.borderRadius, BorderRadius.circular(24));
    expect(decoration.boxShadow, isNotNull);
    expect(decoration.boxShadow!.first.blurRadius, greaterThanOrEqualTo(24));

    final clip = tester.widget<ClipRRect>(
      find
          .ancestor(of: find.byType(PageView), matching: find.byType(ClipRRect))
          .first,
    );
    expect(clip.borderRadius, BorderRadius.circular(24));

    final carousel = tester.getRect(find.byType(FeaturedProviderCarousel));
    final frameRect = tester.getRect(frameFinder);
    expect(carousel.bottom - frameRect.bottom, greaterThanOrEqualTo(40));

    await disposeCarousel(tester);
  });

  testWidgets('advances one card on the fixed interval', (tester) async {
    await pumpCarousel(tester);
    final first = visibleNames(tester).single;

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(visibleNames(tester).single, isNot(first));

    await disposeCarousel(tester);
  });

  testWidgets('advances from right to left during automatic transitions', (
    tester,
  ) async {
    await pumpCarousel(tester);
    final outgoing = visibleNames(tester).single;
    final viewport = tester.getRect(find.byType(PageView));

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getRect(find.text(outgoing)).left, lessThan(viewport.left));

    await disposeCarousel(tester);
  });

  testWidgets('manual swipes sync the timer position', (tester) async {
    await pumpCarousel(tester);
    final first = visibleNames(tester).single;

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    final afterSwipe = visibleNames(tester).single;
    expect(afterSwipe, isNot(first));

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(visibleNames(tester).single, isNot(afterSwipe));

    await disposeCarousel(tester);
  });

  testWidgets('pauses while TickerMode is disabled', (tester) async {
    await pumpCarousel(tester, tickerEnabled: false);
    final first = visibleNames(tester).single;

    await tester.pump(const Duration(seconds: 8));
    expect(visibleNames(tester).single, first);

    await disposeCarousel(tester);
  });

  testWidgets('pauses while scrolled off-screen and resumes in view', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 900),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: FeaturedProviderCarousel(
                    providers: providers,
                    interval: const Duration(seconds: 4),
                    onViewDetails: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final first = visibleNames(tester).single;

    await tester.pump(const Duration(seconds: 8));
    expect(visibleNames(tester).single, first);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -900),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(visibleNames(tester).single, isNot(first));

    await disposeCarousel(tester);
  });

  testWidgets('single provider does not schedule automatic rotation', (
    tester,
  ) async {
    await pumpCarousel(tester, data: [providers.first]);

    await tester.pump(const Duration(seconds: 8));
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await disposeCarousel(tester);
  });

  testWidgets('fits common phone widths and text scales without overflow', (
    tester,
  ) async {
    final sizes = <double>[320, 360, 412];
    final scales = <double>[1, 1.15, 1.5, 2, 3];
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in sizes) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      for (final scale in scales) {
        await pumpConstrainedCarousel(tester, width: width, textScale: scale);
        expect(
          tester.takeException(),
          isNull,
          reason: 'width=$width textScale=$scale',
        );
      }
    }

    await disposeCarousel(tester);
  });

  testWidgets('tap targets return the visible provider', (tester) async {
    ProviderModel? selected;
    await pumpCarousel(
      tester,
      onViewDetails: (provider) => selected = provider,
    );
    final visible = visibleNames(tester).single;

    await tester.tap(find.text('View details'));
    await tester.pump();
    expect(selected?.displayName, visible);

    await tester.tap(find.text(visible));
    await tester.pump();
    expect(selected?.displayName, visible);

    await disposeCarousel(tester);
  });
}
