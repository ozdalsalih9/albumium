import 'package:albumium/services/ad_consent.dart';
import 'package:albumium/widgets/ad_consent_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConsent implements AdConsentController {
  _FakeConsent({this.required_ = true, this.failure});

  final bool required_;
  final String? failure;
  int opened = 0;

  @override
  Future<bool> canChangeChoice() async => required_;

  @override
  Future<String?> showChoiceForm() async {
    opened++;
    return failure;
  }
}

Future<void> _pump(WidgetTester tester, AdConsentController consent) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: AdConsentButton(controller: consent)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(AdConsent.resetForTesting);

  testWidgets('nothing is shown where no consent was ever asked for', (
    tester,
  ) async {
    await _pump(tester, _FakeConsent(required_: false));

    // Most people never see a consent form; a button about a choice they
    // never made would only puzzle them.
    expect(find.byKey(const ValueKey('ad-consent-button')), findsNothing);
  });

  testWidgets('someone who was asked can change their answer', (tester) async {
    final consent = _FakeConsent();
    await _pump(tester, consent);

    final button = find.byKey(const ValueKey('ad-consent-button'));
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(consent.opened, 1);
  });

  testWidgets('a form that will not open says so', (tester) async {
    final consent = _FakeConsent(failure: 'no form');
    await _pump(tester, consent);

    await tester.tap(find.byKey(const ValueKey('ad-consent-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('açılamadı'), findsOneWidget);
  });

  test('the app-wide controller asks for nothing by default', () async {
    // No ad SDK in a test build, so the button must stay out of the way.
    expect(await AdConsent.controller.canChangeChoice(), isFalse);
  });
}
