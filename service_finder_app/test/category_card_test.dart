import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/models/service_category_model.dart';
import 'package:service_finder_app/widgets/category_card.dart';

ServiceCategory category({
  String id = 'plumber',
  String name = 'Plumber',
  String iconPath = '',
  int sortOrder = 1,
}) => ServiceCategory(
  id: id,
  name: name,
  description: '$name services',
  iconPath: iconPath,
  active: true,
  sortOrder: sortOrder,
);

List<ServiceCategory> categories(int count) => [
  for (var index = 0; index < count; index++)
    category(
      id: 'category-$index',
      name: index == count - 1 ? 'Last Category' : 'Category $index',
      sortOrder: index,
    ),
];

Future<void> showCard(
  WidgetTester tester, {
  ServiceCategory? data,
  VoidCallback? onTap,
  double textScale = 1,
  double width = 120,
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
        body: Builder(
          builder: (context) {
            return Center(
              child: SizedBox(
                width: width,
                height: CategoryCard.tileHeight(context, width),
                child: CategoryCard(
                  category: data ?? category(),
                  onTap: onTap ?? () {},
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> showRow(
  WidgetTester tester, {
  double width = 320,
  double textScale = 1,
  void Function(ServiceCategory category)? onTapCategory,
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
        body: Center(
          child: SizedBox(
            width: width,
            child: CategoryCardRow(
              categories: categories(8),
              onTapCategory: onTapCategory ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('card has flush image and label areas', (tester) async {
    await showCard(tester);

    expect(find.byIcon(Icons.home_repair_service), findsOneWidget);
    expect(find.text('Plumber'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsNothing);

    final label = tester.widget<Text>(find.text('Plumber'));
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);
    expect(label.style?.color, Colors.black);
    expect(label.style?.fontWeight, FontWeight.w500);

    final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
    expect(clip.borderRadius, BorderRadius.circular(8));

    final labelStrip = find.byWidgetPredicate((widget) {
      return widget is Container && widget.color == Colors.white;
    });
    expect(labelStrip, findsOneWidget);

    final imageArea = find.ancestor(
      of: find.byIcon(Icons.home_repair_service),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == Colors.white,
      ),
    );
    expect(imageArea, findsWidgets);
    expect(
      tester.getRect(imageArea.first).bottom,
      closeTo(tester.getRect(labelStrip).top, 0.1),
    );
  });

  testWidgets('long labels stay one line without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await showCard(
      tester,
      width: 90,
      textScale: 3,
      data: category(name: 'Air Conditioner Repair'),
    );

    expect(tester.takeException(), isNull);
    final label = tester.widget<Text>(find.text('Air Conditioner Repair'));
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);
  });

  testWidgets('provided category images are full bleed', (tester) async {
    await showCard(
      tester,
      data: category(iconPath: 'https://example.com/category.png'),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.cover);
  });

  testWidgets('card taps invoke the callback', (tester) async {
    var taps = 0;
    await showCard(tester, onTap: () => taps++);

    await tester.tap(find.text('Plumber'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets(
    'row shows two cards and a partial third, then scrolls through all',
    (tester) async {
      await showRow(tester, width: 320);

      final cardWidth = tester.getSize(find.byType(CategoryCard).first).width;
      expect(cardWidth, closeTo(CategoryCardRow.cardWidth(320), 0.1));

      final rowRect = tester.getRect(find.byType(CategoryCardRow));
      final thirdRect = tester.getRect(find.text('Category 2'));
      expect(thirdRect.left, lessThan(rowRect.right));
      expect(thirdRect.right, greaterThan(rowRect.right));

      expect(find.text('Last Category'), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(-1000, 0));
      await tester.pumpAndSettle();
      expect(find.text('Last Category'), findsOneWidget);
    },
  );

  testWidgets('row taps return the selected category', (tester) async {
    ServiceCategory? selected;
    await showRow(tester, onTapCategory: (category) => selected = category);

    await tester.tap(find.text('Category 0'));
    await tester.pump();

    expect(selected?.id, 'category-0');
  });
}
