import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/models/provider_model.dart';
import 'package:service_finder_app/widgets/featured_provider_card.dart';

ProviderModel provider({
  String id = 'provider-1',
  String name = 'Alex Morgan',
  List<String> categories = const ['plumber', 'electrician'],
  double rating = 4.8,
  int reviews = 27,
  int jobs = 42,
}) => ProviderModel(
  providerId: id,
  displayName: name,
  categoryIds: categories,
  availabilityStatus: 'available',
  verificationStatus: 'verified',
  ratingAverage: rating,
  reviewCount: reviews,
  completedJobCount: jobs,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Future<void> showCard(
  WidgetTester tester, {
  ProviderModel? data,
  VoidCallback? onViewDetails,
  double textScale = 1,
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
          child: Builder(
            builder: (context) {
              final cardData = data ?? provider();
              const width = 340.0;
              return Center(
                child: SizedBox(
                  width: width,
                  height: FeaturedProviderCard.preferredHeight(
                    context,
                    width: width,
                    provider: cardData,
                  ),
                  child: FeaturedProviderCard(
                    provider: cardData,
                    onViewDetails: onViewDetails ?? () {},
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('matches the requested white floating card structure', (
    tester,
  ) async {
    await showCard(tester);

    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('27 reviews'), findsOneWidget);
    expect(find.text('Plumber'), findsOneWidget);
    expect(find.text('Electrician'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('42 Jobs completed'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('View details'), findsOneWidget);
    expect(find.text('Save'), findsNothing);

    final card = tester.widget<Container>(
      find.byWidgetPredicate((widget) {
        if (widget is! Container || widget.decoration is! BoxDecoration) {
          return false;
        }
        final decoration = widget.decoration! as BoxDecoration;
        return decoration.color == Colors.white &&
            (decoration.boxShadow?.isNotEmpty ?? false);
      }).first,
    );
    final decoration = card.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(24));
    expect(decoration.boxShadow!.first.blurRadius, greaterThanOrEqualTo(24));

    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'View details'),
    );
    expect(button.style?.backgroundColor?.resolve({}), Colors.black);
    expect(button.style?.foregroundColor?.resolve({}), Colors.white);
  });

  testWidgets('button and whole card both open provider details', (
    tester,
  ) async {
    var taps = 0;
    await showCard(tester, onViewDetails: () => taps++);

    await tester.tap(find.text('View details'));
    await tester.pump();
    expect(taps, 1);

    await tester.tap(find.text('Alex Morgan'));
    await tester.pump();
    expect(taps, 2);
  });

  testWidgets('narrow screens and large text do not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await showCard(tester, textScale: 3);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('View details'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
