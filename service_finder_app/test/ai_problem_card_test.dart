import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/widgets/ai_problem_card.dart';
import 'package:service_finder_app/widgets/customer_search_bar.dart';

Widget buttonApp({
  VoidCallback? onPressed,
  bool reduceMotion = false,
  bool enabled = true,
  double scale = 1,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reduceMotion,
      textScaler: TextScaler.linear(scale),
    ),
    child: child!,
  ),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: TickerMode(
        enabled: enabled,
        child: AiProblemCard(onPressed: onPressed ?? () {}),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'compact AI button has no tooltip or shadow and invokes the existing action',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        buttonApp(onPressed: () => taps++, reduceMotion: true),
      );
      expect(find.text('AI'), findsOneWidget);
      expect(find.text('Describe your problem'), findsNothing);
      expect(find.byType(Tooltip), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              ((widget.decoration as BoxDecoration).boxShadow?.isNotEmpty ??
                  false),
        ),
        findsNothing,
      );
      expect(find.text('Get an AI-assisted suggestion'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(
        tester.getSize(find.byType(AiProblemCard)).height,
        greaterThanOrEqualTo(56),
      );
      expect(tester.getSize(find.byType(AiProblemCard)).width, 64);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Describe your problem'), findsOneWidget);
      semantics.dispose();
      await tester.tap(find.text('AI'));
      await tester.pump();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'narrow screens and large text keep the label readable and action tappable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var taps = 0;
      for (final scale in [1.0, 2.0, 3.0]) {
        await tester.pumpWidget(
          buttonApp(onPressed: () => taps++, reduceMotion: true, scale: scale),
        );
        expect(tester.takeException(), isNull);
        expect(tester.widget<Text>(find.text('AI')).overflow, isNull);
        await tester.tap(find.text('AI'));
        await tester.pump();
      }
      expect(taps, 3);
    },
  );

  testWidgets('color animation respects reduced motion and inactive tabs', (
    tester,
  ) async {
    await tester.pumpWidget(buttonApp());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(buttonApp(reduceMotion: true));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(buttonApp(enabled: false));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(buttonApp());
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'color motion pauses when scrolled out of view and resumes on return',
    (tester) async {
      final scroll = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scroll,
              child: Column(
                children: [
                  AiProblemCard(onPressed: () {}),
                  const SizedBox(height: 1600),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      scroll.jumpTo(900);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      scroll.jumpTo(0);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
      scroll.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'background colors visibly move while the action text remains fixed',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey('ai_button_boundary'),
              child: SizedBox(
                width: 320,
                child: AiProblemCard(onPressed: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('ai_button_boundary')),
      );
      Future<List<int>?> pixels() => tester.runAsync(() async {
        final image = await boundary.toImage();
        try {
          return (await image.toByteData())!.buffer.asUint8List().toList();
        } finally {
          image.dispose();
        }
      });
      final before = await pixels();
      final textPosition = tester.getTopLeft(find.text('AI'));
      await tester.pump(const Duration(seconds: 2));
      final after = await pixels();
      expect(before, isNotNull);
      expect(after, isNot(equals(before)));
      expect(tester.getTopLeft(find.text('AI')), textPosition);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'search and AI stay in one aligned row with independent actions at large text sizes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TextEditingController();
      var taps = 0;
      String? query;
      for (final scale in [1.0, 2.0, 3.0]) {
        controller.clear();
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: CustomerSearchBar(
                  controller: controller,
                  onChanged: (value) => query = value,
                  onAiPressed: () => taps++,
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final searchRect = tester.getRect(
          find.byKey(const ValueKey('customer_search_surface')),
        );
        final aiSurface = find.descendant(
          of: find.byType(AiProblemCard),
          matching: find.byType(CustomPaint),
        );
        final aiRect = tester.getRect(aiSurface.first);
        expect(aiRect.height, searchRect.height);
        expect(aiRect.top, searchRect.top);
        expect(aiRect.left - searchRect.right, 10);
        expect(aiRect.width, lessThan(searchRect.width));
        expect(find.text('Search services'), findsOneWidget);
        expect(
          tester.getCenter(find.byIcon(Icons.search)).dy,
          closeTo(searchRect.center.dy, 0.1),
        );
        expect(
          tester.getCenter(find.text('Search services')).dy,
          closeTo(searchRect.center.dy, 0.1),
        );
        final input = tester.widget<TextField>(find.byType(TextField));
        expect(input.decoration?.border, InputBorder.none);
        expect(input.decoration?.filled, isFalse);
        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();
        expect(
          tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
          isTrue,
        );
        await tester.enterText(find.byType(TextField), 'plumber');
        expect(query, 'plumber');
        await tester.tap(find.text('AI'));
        await tester.pump();
      }
      expect(taps, 3);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
