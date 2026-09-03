import 'package:albumium/screens/special_card_studio_screen.dart';
import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpStudioAt(WidgetTester tester, Size logicalSize) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: SpecialCardStudioScreen(project: createSpecialCardProject()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final logicalSize in const [Size(600, 960), Size(720, 1280)]) {
    final viewportLabel =
        '${logicalSize.width.toInt()}x${logicalSize.height.toInt()}';
    testWidgets(
      '$viewportLabel tablet portrait keeps a full bottom-panel canvas',
      (tester) async {
        await _pumpStudioAt(tester, logicalSize);

        expect(
          find.byKey(const ValueKey('card-controls-bottom')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('card-controls-side')), findsNothing);
        expect(tester.takeException(), isNull);

        final canvasSize = tester.getSize(find.byType(AlbumPageCanvas));
        expect(canvasSize.width, greaterThan(400));
        expect(canvasSize.width / canvasSize.height, closeTo(5 / 7, .01));
      },
    );
  }

  testWidgets('960x600 tablet landscape uses the bounded side panel', (
    tester,
  ) async {
    await _pumpStudioAt(tester, const Size(960, 600));

    expect(find.byKey(const ValueKey('card-controls-side')), findsOneWidget);
    expect(find.byKey(const ValueKey('card-controls-bottom')), findsNothing);
    expect(tester.takeException(), isNull);

    final canvasRect = tester.getRect(find.byType(AlbumPageCanvas));
    final controlsRect = tester.getRect(
      find.byKey(const ValueKey('card-controls-side')),
    );
    expect(controlsRect.left, greaterThan(canvasRect.right));
  });
}
