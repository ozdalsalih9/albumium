import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/preview_screen.dart';
import 'package:albumium/theme/book_theme.dart';
import 'package:albumium/widgets/page_flip_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AlbumModel _album({int pages = 2}) {
  final now = DateTime(2026, 1, 1);
  final theme = albumThemes.first;
  return AlbumModel(
    id: 'a1',
    title: 'Test Albümü',
    themeId: theme.id,
    createdAt: now,
    updatedAt: now,
    pages: [
      for (var i = 0; i < pages; i++)
        AlbumPageModel(
          id: 'p$i',
          backgroundColor: theme.pageColor.toARGB32(),
        ),
    ],
  );
}

/// Ekran boyutunu sabitler ve test bitince geri alır.
void _useScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Kontrol katmanının görünürlüğü; üst çubuğu saran solma katmanından okunur.
double _chromeOpacity(WidgetTester tester) {
  final finder = find.ancestor(
    of: find.byTooltip('Geri'),
    matching: find.byType(AnimatedOpacity),
  );
  return tester.widget<AnimatedOpacity>(finder.first).opacity;
}

void main() {
  testWidgets('kitabın ortasına dokunmak kontrolleri gizler ve geri getirir', (
    tester,
  ) async {
    _useScreen(tester, const Size(400, 800));
    await tester.pumpWidget(MaterialApp(home: PreviewScreen(album: _album())));
    await tester.pumpAndSettle();

    expect(_chromeOpacity(tester), 1);

    // Orta bant: ne ileri ne geri, yalnızca arayüzü gizler.
    final book = find.byType(BookFrame);
    final size = tester.getSize(book);
    final topLeft = tester.getTopLeft(book);
    await tester.tapAt(topLeft + Offset(size.width * 0.45, size.height / 2));
    await tester.pumpAndSettle();
    expect(_chromeOpacity(tester), 0);

    // Sayfa da değişmemiş olmalı.
    expect(find.text('Kapak'), findsOneWidget);

    await tester.tapAt(topLeft + Offset(size.width * 0.45, size.height / 2));
    await tester.pumpAndSettle();
    expect(_chromeOpacity(tester), 1);
  });

  testWidgets('dar dikey ekranda tek sayfa gösterilir', (tester) async {
    _useScreen(tester, const Size(400, 800));
    await tester.pumpWidget(MaterialApp(home: PreviewScreen(album: _album())));
    await tester.pumpAndSettle();

    final ratios = tester
        .widgetList<AspectRatio>(find.byType(AspectRatio))
        .map((widget) => widget.aspectRatio);
    expect(ratios, contains(closeTo(BookTheme.pageAspect, 0.001)));
    expect(ratios, isNot(contains(closeTo(BookTheme.pageAspect * 2, 0.001))));
  });

  testWidgets('geniş yatay ekranda iki sayfalı kitap açılır', (tester) async {
    _useScreen(tester, const Size(1200, 800));
    await tester.pumpWidget(MaterialApp(home: PreviewScreen(album: _album())));
    await tester.pumpAndSettle();

    final ratios = tester
        .widgetList<AspectRatio>(find.byType(AspectRatio))
        .map((widget) => widget.aspectRatio);
    expect(ratios, contains(closeTo(BookTheme.pageAspect * 2, 0.001)));
  });

  testWidgets('çok sayfalı albümde nokta yerine ilerleme çubuğu kullanılır', (
    tester,
  ) async {
    _useScreen(tester, const Size(400, 800));
    await tester.pumpWidget(
      MaterialApp(home: PreviewScreen(album: _album(pages: 20))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
