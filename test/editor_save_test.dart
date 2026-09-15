import 'dart:async';

import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/editor_screen.dart';
import 'package:albumium/services/album_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _Store extends InMemorySharedPreferencesStore {
  _Store() : super.empty();
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (gate != null) await gate!.future;
    if (fail) return false;
    return super.setValue(type, key, value);
  }
}

void main() {
  testWidgets(
    'editor saves new pages on save, exit and background; retries failures',
    (tester) async {
      for (final action in ['save', 'back', 'background', 'failure']) {
        SharedPreferences.setMockInitialValues({});
        final store = _Store();
        SharedPreferencesStorePlatform.instance = store;
        final now = DateTime(2026);
        final album = AlbumModel(
          id: 'save-test',
          title: 'Anılar',
          themeId: 'vintage_diary',
          createdAt: now,
          updatedAt: now,
          pages: [AlbumPageModel(id: 'first', backgroundColor: 0xFFF2E8D3)],
        );
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(body: Text('Library')),
          ),
        );
        navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => EditorScreen(album: album)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Sayfa ekle'));
        await tester.pump();
        album.pages.last.elements.add(
          AlbumElementModel(
            id: 'text',
            type: AlbumElementType.text,
            content: 'Kalıcı anı',
            x: .1,
            y: .1,
            width: .5,
            height: .2,
          ),
        );

        if (action == 'background') {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
        } else if (action == 'back' || action == 'failure') {
          store.fail = action == 'failure';
          store.gate = Completer<void>();
          await navigator.currentState!.maybePop();
          await tester.pump();
          expect(find.byType(EditorScreen), findsOneWidget);
          final saveAndExit = find.text('Kaydet ve Çık');
          if (saveAndExit.evaluate().isNotEmpty) {
            await tester.tap(saveAndExit);
            await tester.pump();
          }
          store.gate!.complete();
        } else {
          await tester.tap(find.byKey(const ValueKey('editor-save')));
        }
        await tester.pumpAndSettle();
        if (action == 'failure') {
          expect(find.byType(EditorScreen), findsOneWidget);
          expect(find.text('Kaydedilemedi. Tekrar dene.'), findsOneWidget);
          store.fail = false;
          await tester.tap(find.byKey(const ValueKey('editor-save')));
          await tester.pumpAndSettle();
        }
        if (action == 'back') expect(find.text('Library'), findsOneWidget);
        final loaded = await AlbumStorage.instance.loadAlbums();
        expect(loaded.single.pages, hasLength(2));
        expect(loaded.single.pages.last.elements.single.content, 'Kalıcı anı');
        if (action == 'background') {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
