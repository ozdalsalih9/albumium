import 'package:albumium/widgets/page_flip_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(PageFlipController controller, ValueChanged<int> onChanged) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          height: 400,
          child: PageFlipView(
            controller: controller,
            itemCount: 3,
            onPageChanged: onChanged,
            itemBuilder: (context, index) => ColoredBox(
              color: Colors.white,
              child: Center(child: Text('sayfa $index')),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Parmağı adım adım hareket ettirir; tek seferlik sürüklemenin ürettiği
/// yapay yüksek hız yerine gerçekçi bir hız oluşsun diye.
Future<void> _dragBy(
  WidgetTester tester,
  double totalDx, {
  int steps = 8,
  Duration stepDelay = const Duration(milliseconds: 60),
}) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(PageFlipView)),
  );
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(totalDx / steps, 0));
    await tester.pump(stepDelay);
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('denetleyici ileri ve geri sayfa çevirir', (tester) async {
    final controller = PageFlipController();
    final seen = <int>[];
    await tester.pumpWidget(_harness(controller, seen.add));

    expect(find.text('sayfa 0'), findsOneWidget);
    expect(find.text('sayfa 1'), findsNothing);

    controller.next();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Çevirme sürerken kalkan yaprak ile altındaki sayfa birlikte görünür.
    expect(find.text('sayfa 0'), findsWidgets);
    expect(find.text('sayfa 1'), findsWidgets);

    await tester.pumpAndSettle();
    expect(seen, [1]);
    expect(controller.page, 1);
    expect(find.text('sayfa 1'), findsOneWidget);
    expect(find.text('sayfa 0'), findsNothing);

    controller.previous();
    await tester.pumpAndSettle();
    expect(seen, [1, 0]);
    expect(controller.page, 0);
    expect(find.text('sayfa 0'), findsOneWidget);
  });

  testWidgets('son sayfadan ileri, ilk sayfadan geri çevrilemez', (
    tester,
  ) async {
    final controller = PageFlipController();
    final seen = <int>[];
    await tester.pumpWidget(_harness(controller, seen.add));

    controller.previous();
    await tester.pumpAndSettle();
    expect(seen, isEmpty);
    expect(controller.page, 0);

    controller.jumpTo(2);
    await tester.pumpAndSettle();
    controller.next();
    await tester.pumpAndSettle();
    expect(controller.page, 2);
  });

  testWidgets('kısa sürükleme yaprağı geri yaslar', (tester) async {
    final controller = PageFlipController();
    final seen = <int>[];
    await tester.pumpWidget(_harness(controller, seen.add));

    await _dragBy(tester, -48);

    expect(seen, isEmpty);
    expect(controller.page, 0);
    expect(find.text('sayfa 0'), findsOneWidget);
  });

  testWidgets('yeterince sürüklemek çevirmeyi tamamlar', (tester) async {
    final controller = PageFlipController();
    final seen = <int>[];
    await tester.pumpWidget(_harness(controller, seen.add));

    await _dragBy(tester, -240);

    expect(seen, [1]);
    expect(controller.page, 1);
    expect(find.text('sayfa 1'), findsOneWidget);
  });

  testWidgets('FlipFrame ilerlemeye göre yüz değiştirir', (tester) async {
    Future<void> pumpAt(double progress) => tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 400,
          child: FlipFrame(
            progress: progress,
            front: const Text('ön', textDirection: TextDirection.ltr),
            back: const Text('arka', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );

    await pumpAt(0);
    expect(find.text('ön'), findsOneWidget);
    expect(find.text('arka'), findsOneWidget);

    // Yaprak tamamen çevrildiğinde ön yüz artık çizilmez.
    await pumpAt(1);
    expect(find.text('ön'), findsNothing);
    expect(find.text('arka'), findsOneWidget);
  });
}
