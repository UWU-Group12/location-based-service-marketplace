import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/core/app_colors.dart';
import 'package:service_finder_app/core/widgets/floating_glass_navigation_bar.dart';
import 'package:service_finder_app/widgets/greeting_header.dart';

const _items = [
  BottomNavigationBarItem(
    icon: Icon(Icons.home_outlined),
    activeIcon: Icon(Icons.home),
    label: 'Home',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.receipt_long_outlined),
    activeIcon: Icon(Icons.receipt_long),
    label: 'Requests',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.person_outline),
    activeIcon: Icon(Icons.person),
    label: 'Profile',
  ),
];

Widget shell({required Widget page, int index = 0, double scale = 1}) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        extendBody: true,
        body: page,
        bottomNavigationBar: FloatingGlassNavigationBar(
          currentIndex: index,
          onTap: (_) {},
          items: _items,
        ),
      ),
    );

/// The rounded glass pill sits inside the bar's outer safe-area padding,
/// so measure that surface rather than the full-width navigation slot.
Finder pill() => find
    .ancestor(
      of: find.byType(AnimatedAlign),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).gradient != null,
      ),
    )
    .first;

void main() {
  testWidgets(
    'greeting greets with Hi and keeps the name in default headline black',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GreetingHeader(firstName: 'Alex')),
        ),
      );
      expect(find.text('Hi'), findsOneWidget);
      expect(find.text('Good morning'), findsNothing);
      expect(find.text('Alex'), findsOneWidget);

      final textTheme = Theme.of(
        tester.element(find.byType(GreetingHeader)),
      ).textTheme;
      final greeting = tester.widget<Text>(find.text('Hi'));
      final name = tester.widget<Text>(find.text('Alex'));
      expect(greeting.style?.fontSize, textTheme.headlineMedium?.fontSize);
      expect(
        greeting.style?.color,
        AppColors.textPrimary.withValues(alpha: 0.6),
      );
      expect(name.style?.fontSize, textTheme.headlineMedium?.fontSize);
      expect(name.style?.color, textTheme.headlineMedium?.color);
      expect(name.style?.color, isNot(AppColors.primary));
      expect(
        tester.getTopLeft(find.text('Alex')).dy -
            tester.getTopLeft(find.text('Hi')).dy,
        greaterThan(0),
      );
    },
  );

  testWidgets(
    'page content extends behind the floating bar instead of a solid strip',
    (tester) async {
      final page = ColoredBox(
        key: const ValueKey('page'),
        color: const Color(0xFF102030),
        child: const SizedBox.expand(),
      );
      await tester.pumpWidget(shell(page: page));
      final bar = tester.getRect(pill());
      final screen = tester.getSize(find.byType(Scaffold));

      // The page fills the whole screen, so its colour remains visible in the
      // gaps beside and below the rounded bar.
      expect(
        tester.getRect(find.byKey(const ValueKey('page'))).height,
        screen.height,
      );
      // The pill is inset by the bar's own padding, so page content is
      // exposed both beside it and in the strip below it.
      expect(bar.left, greaterThan(0));
      expect(bar.right, lessThan(screen.width));
      expect(bar.bottom, lessThan(screen.height));
    },
  );

  testWidgets('bar overlays content rather than displacing it', (tester) async {
    final page = ColoredBox(
      key: const ValueKey('page'),
      color: const Color(0xFF102030),
      child: const SizedBox.expand(),
    );
    await tester.pumpWidget(shell(page: page));
    final bar = tester.getRect(pill());
    final pageRect = tester.getRect(find.byKey(const ValueKey('page')));

    // The page still occupies the whole screen, so it sits behind the bar
    // instead of stopping above it.
    expect(
      pageRect.bottom,
      closeTo(tester.getSize(find.byType(Scaffold)).height, 0.1),
    );
    expect(pageRect.bottom, greaterThan(bar.top));
  });

  testWidgets('clearance keeps the last item fully above the floating bar', (
    tester,
  ) async {
    Widget page(BuildContext context) => ListView(
      padding: EdgeInsets.only(
        bottom: FloatingGlassNavigationBar.clearanceFor(context) + 8,
      ),
      children: const [SizedBox(height: 900), Text('Log Out')],
    );
    await tester.pumpWidget(shell(page: Builder(builder: page)));

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    final bar = tester.getRect(pill());
    final last = tester.getRect(find.text('Log Out'));
    expect(last.bottom, lessThanOrEqualTo(bar.top));
    expect(last.bottom, greaterThan(bar.top - 40));
  });

  testWidgets('clearance grows for larger text and system bottom insets', (
    tester,
  ) async {
    Future<double> measure(TextScaler scaler, double bottomPadding) async {
      late double value;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            textScaler: scaler,
            viewPadding: EdgeInsets.only(bottom: bottomPadding),
          ),
          child: Builder(
            builder: (context) {
              value = FloatingGlassNavigationBar.clearanceFor(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return value;
    }

    final base = await measure(const TextScaler.linear(1), 0);
    final largerText = await measure(const TextScaler.linear(2), 0);
    final withInset = await measure(const TextScaler.linear(1), 34);

    expect(base, greaterThan(0));
    expect(largerText, greaterThan(base));
    expect(withInset, greaterThan(base));
  });
}
