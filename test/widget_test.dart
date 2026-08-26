import 'package:albumium/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('empty library opens the album creation flow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AlbumiumApp());
    await tester.pumpAndSettle();

    expect(find.text('ALBUMIUM'), findsOneWidget);
    expect(find.text('Albüm oluştur'), findsOneWidget);

    await tester.tap(find.text('Albüm oluştur'));
    await tester.pumpAndSettle();

    expect(find.text('Hangi hikâyeyi anlatıyoruz?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('app palette changes without leaving the theme sheet', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AlbumiumApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Uygulama temasını değiştir'));
    await tester.pumpAndSettle();
    expect(find.text('Uygulama görünümü'), findsOneWidget);

    await tester.tap(find.text('Gül Pembesi'));
    await tester.pumpAndSettle();

    expect(find.text('Uygulama görünümü'), findsOneWidget);
    expect(find.text('Gül Pembesi temasını kullan'), findsOneWidget);
    expect(find.text('ALBUMIUM'), findsOneWidget);
  });
}
