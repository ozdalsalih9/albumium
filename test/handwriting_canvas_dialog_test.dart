import 'package:albumium/theme/albumium_app_theme.dart';
import 'package:albumium/widgets/handwriting_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'handwriting toolbar stays visible and usable with a light app palette',
    (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AlbumiumAppTheme.light(AlbumiumThemeId.obsidian),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HandwritingCanvasDialog(),
                  ),
                ),
                child: const Text('Çizimi aç'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Çizimi aç'));
      await tester.pumpAndSettle();

      const foreground = Color(0xFFFFF8EC);
      const disabledForeground = Color(0x6BFFF8EC);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      final title = tester.widget<Text>(find.text('Elle Yaz & Çiz'));
      final undoFinder = find.byKey(const ValueKey('handwriting-undo'));

      expect(appBar.backgroundColor, const Color(0xFF241F1C));
      expect(appBar.foregroundColor, foreground);
      expect(title.style?.color, foreground);
      expect(undoFinder, findsOneWidget);
      expect(find.byKey(const ValueKey('handwriting-redo')), findsOneWidget);
      expect(find.byKey(const ValueKey('handwriting-clear')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('handwriting-save-compact')),
        findsOneWidget,
      );

      final disabledUndo = tester.widget<IconButton>(undoFinder);
      expect(disabledUndo.onPressed, isNull);
      expect(
        disabledUndo.style?.foregroundColor?.resolve({WidgetState.disabled}),
        disabledForeground,
      );

      await tester.drag(
        find.byKey(const ValueKey('handwriting-drawing-area')),
        const Offset(28, 18),
      );
      await tester.pump();

      expect(tester.widget<IconButton>(undoFinder).onPressed, isNotNull);
      await tester.tap(undoFinder);
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('handwriting-redo')))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
