import 'dart:math' as math;

import 'package:albumium/models/album_models.dart';
import 'package:albumium/widgets/page_curl.dart';
import 'package:albumium/widgets/physical_book_spread.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
