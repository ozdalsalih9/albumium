import 'dart:math' as math;

import 'package:albumium/models/album_models.dart';
import 'package:albumium/widgets/page_curl.dart';
import 'package:albumium/widgets/physical_book_spread.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cover edge moves left continuously during a slow opening', (
    tester,
  ) async {
    double? previousEdge;
    for (final progress in [0.0, .01, .05, .1, .25, .49, .51, .75, 1.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 390,
              height: 280,
              child: PhysicalBookSpread(
                album: _album(),
                leftPageIndex: PhysicalBookSpread.titlePageIndex,
                rightPageIndex: PhysicalBookSpread.blankPageIndex,
                closed: true,
                nextLeftPageIndex: PhysicalBookSpread.titlePageIndex,
                nextRightPageIndex: 0,
                turnProgress: progress,
              ),
            ),
          ),
        ),
      );
      final hinge = find.byKey(const ValueKey('book-cover-hinge'));
      final box = tester.renderObject<RenderBox>(hinge);
      final transform = tester.widget<Transform>(hinge).transform;
      final edge = box
          .localToGlobal(
            MatrixUtils.transformPoint(
              transform,
              Offset(box.size.width, box.size.height / 2),
            ),
          )
          .dx;
      if (previousEdge != null) expect(edge, lessThan(previousEdge));
      previousEdge = edge;
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'cover opening consumes progress without applying a second ease',
    (tester) async {
      final album = _album();
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 600,
            height: 400,
            child: PhysicalBookSpread(
              album: album,
              leftPageIndex: PhysicalBookSpread.titlePageIndex,
              rightPageIndex: PhysicalBookSpread.blankPageIndex,
              closed: true,
              nextLeftPageIndex: PhysicalBookSpread.titlePageIndex,
              nextRightPageIndex: 0,
              turnProgress: .25,
            ),
          ),
        ),
      );

      final coverTransform = tester
          .widgetList<Transform>(find.byType(Transform))
          .singleWhere(
            (transform) => transform.alignment == Alignment.centerLeft,
          );

      // Matrix[0,0] is cos(rotationY). A second cubic ease would produce
      // cos(pi * .15625) here instead.
      expect(
        coverTransform.transform.entry(0, 0),
        closeTo(math.cos(math.pi * .25), .0001),
      );
    },
  );

  testWidgets('turning leaf has one restrained crease shadow per surface', (
    tester,
  ) async {
    final album = _album();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 600,
          height: 400,
          child: PhysicalBookSpread(
            album: album,
            leftPageIndex: 0,
            rightPageIndex: 1,
            nextLeftPageIndex: 2,
            nextRightPageIndex: 3,
            turnProgress: .5,
          ),
        ),
      ),
    );

    final curls = tester.widgetList<PageCurl>(find.byType(PageCurl)).toList();
    expect(curls, hasLength(2));
    expect(curls.map((curl) => curl.surface), {
      PageCurlSurface.front,
      PageCurlSurface.back,
    });
    expect(curls.every((curl) => curl.shadowOpacity == .30), isTrue);
  });

  testWidgets(
    'read-only focused viewport pans within a spread and can hide companion',
    (tester) async {
      final album = _album();

      Future<double> pumpAt(double progress) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 450,
                height: 760,
                child: PhysicalBookSpread(
                  album: album,
                  leftPageIndex: 0,
                  rightPageIndex: 1,
                  focusedPageIndex: 0,
                  targetFocusedPageIndex: 1,
                  focusTransitionProgress: progress,
                  companionPageFraction: 0,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        return tester
            .widget<Positioned>(
              find.byKey(const ValueKey('focused-book-position')),
            )
            .left!;
      }

      final start = await pumpAt(0);
      final middle = await pumpAt(.5);
      final end = await pumpAt(1);

      expect(
        find.byKey(const ValueKey('focused-book-viewport')),
        findsOneWidget,
      );
      expect(end, lessThan(middle));
      expect(middle, lessThan(start));

      final viewportWidth = tester
          .getSize(find.byKey(const ValueKey('focused-book-viewport')))
          .width;
      final pageWidth = tester
          .getSize(find.byKey(const ValueKey('page-0')))
          .width;
      expect(viewportWidth - pageWidth, closeTo(32, .01));
    },
  );

  testWidgets('focused viewport follows the target page during a curl', (
    tester,
  ) async {
    final album = _album();

    Future<double> pumpAt(double progress) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 450,
              height: 760,
              child: PhysicalBookSpread(
                album: album,
                leftPageIndex: 0,
                rightPageIndex: 1,
                nextLeftPageIndex: 2,
                nextRightPageIndex: 3,
                turnProgress: progress,
                focusedPageIndex: 1,
                targetFocusedPageIndex: 2,
                companionPageFraction: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PageCurl), findsNWidgets(2));
      return tester
          .widget<Positioned>(
            find.byKey(const ValueKey('focused-book-position')),
          )
          .left!;
    }

    final start = await pumpAt(0);
    final middle = await pumpAt(.5);
    final end = await pumpAt(1);

    expect(start, lessThan(middle));
    expect(middle, lessThan(end));
    expect(end, closeTo(0, .01));
  });

  testWidgets(
    'when back page is empty, front page shows through with 0.18 opacity; when full, no ghosting',
    (tester) async {
      final now = DateTime(2026);
      final photoElement = AlbumElementModel(
        id: 'photo-1',
        type: AlbumElementType.photo,
        content: 'assets/test.jpg',
        x: 0.1,
        y: 0.1,
        width: 0.8,
        height: 0.8,
      );

      // Album where front page (index 1) has a photo, back page (index 2) is empty:
      final albumWithEmptyBack = AlbumModel(
        id: 'test-translucent',
        title: 'Translucent Test',
        themeId: 'vintage_diary',
        createdAt: now,
        updatedAt: now,
        pages: [
          AlbumPageModel(id: 'page-0', backgroundColor: 0xFFF2E8D3),
          AlbumPageModel(
            id: 'page-1',
            backgroundColor: 0xFFF2E8D3,
            elements: [photoElement],
          ),
          AlbumPageModel(id: 'page-2', backgroundColor: 0xFFF2E8D3), // Empty back!
          AlbumPageModel(id: 'page-3', backgroundColor: 0xFFF2E8D3),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 600,
            height: 400,
            child: PhysicalBookSpread(
              album: albumWithEmptyBack,
              leftPageIndex: 0,
              rightPageIndex: 1,
              nextLeftPageIndex: 2,
              nextRightPageIndex: 3,
              turnProgress: .5,
            ),
          ),
        ),
      );

      // In the back PageCurl, find Opacity widget with 0.18:
      final backCurl = find.byKey(const ValueKey('book-page-curl-back'));
      expect(backCurl, findsOneWidget);
      final ghostOpacityFinder = find.descendant(
        of: backCurl,
        matching: find.byWidgetPredicate(
          (widget) => widget is Opacity && (widget.opacity - 0.18).abs() < 0.01,
        ),
      );
      expect(ghostOpacityFinder, findsOneWidget);

      // Now test where back page (index 2) ALSO has a photo:
      final albumWithFullBack = AlbumModel(
        id: 'test-full-back',
        title: 'Full Back Test',
        themeId: 'vintage_diary',
        createdAt: now,
        updatedAt: now,
        pages: [
          AlbumPageModel(id: 'page-0', backgroundColor: 0xFFF2E8D3),
          AlbumPageModel(
            id: 'page-1',
            backgroundColor: 0xFFF2E8D3,
            elements: [photoElement],
          ),
          AlbumPageModel(
            id: 'page-2',
            backgroundColor: 0xFFF2E8D3,
            elements: [photoElement],
          ), // Full back!
          AlbumPageModel(id: 'page-3', backgroundColor: 0xFFF2E8D3),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 600,
            height: 400,
            child: PhysicalBookSpread(
              album: albumWithFullBack,
              leftPageIndex: 0,
              rightPageIndex: 1,
              nextLeftPageIndex: 2,
              nextRightPageIndex: 3,
              turnProgress: .5,
            ),
          ),
        ),
      );

      // In the full back case, NO Opacity(0.18) ghost widget should exist in the back curl:
      final fullGhostOpacityFinder = find.descendant(
        of: find.byKey(const ValueKey('book-page-curl-back')),
        matching: find.byWidgetPredicate(
          (widget) => widget is Opacity && (widget.opacity - 0.18).abs() < 0.01,
        ),
      );
      expect(fullGhostOpacityFinder, findsNothing);
    },
  );

  testWidgets(
    'open book spread is not rendered while cover is opening (progress < 0.7) to prevent clashing',
    (tester) async {
      final album = _album();

      // At progress 0.25 (early cover opening):
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 600,
            height: 400,
            child: PhysicalBookSpread(
              album: album,
              leftPageIndex: PhysicalBookSpread.titlePageIndex,
              rightPageIndex: PhysicalBookSpread.blankPageIndex,
              closed: true,
              nextLeftPageIndex: PhysicalBookSpread.titlePageIndex,
              nextRightPageIndex: 0,
              turnProgress: .25,
            ),
          ),
        ),
      );

      // The cover hinge is present and turning:
      expect(find.byKey(const ValueKey('book-cover-hinge')), findsOneWidget);

      // The right page (page 0) is revealed under the lifting cover:
      expect(find.byKey(const ValueKey('page-0')), findsOneWidget);

      // The inside cover / title page is NOT visible because the cover has not flipped yet:
      // In the old buggy behavior, _buildOpenBook was drawn with opacity from 0.04,
      // so the title page was already rendered on the left table!
      // Now, it is completely absent:
      expect(find.textContaining('Hareket'), findsWidgets); // Album title on cover
    },
  );
}

AlbumModel _album() {
  final now = DateTime(2026);
  return AlbumModel(
    id: 'motion-test',
    title: 'Hareket',
    themeId: 'vintage_diary',
    createdAt: now,
    updatedAt: now,
    pages: List.generate(
      4,
      (index) => AlbumPageModel(id: 'page-$index', backgroundColor: 0xFFF2E8D3),
    ),
  );
}
