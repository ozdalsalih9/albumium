import 'package:albumium/services/feature_entitlements.dart';
import 'package:flutter_test/flutter_test.dart';

/// Storage is deliberately never mocked in this file.
///
/// Reading preferences then fails exactly as it does on a device whose data is
/// locked — and as it does in the many widget tests that build the editor or
/// the video screen without installing a mock. The ledger has to survive that:
/// the screen opens, and nothing paid for is handed out by accident.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'unreachable storage leaves the app usable and everything shut',
    () async {
      final features = FeatureEntitlements();

      await features.initialize();

      expect(features.isInitialized, isTrue);
      expect(features.purchasedFeatureIds, isEmpty);
      for (final feature in AlbumiumFeature.values) {
        expect(features.isUnlocked(feature), isFalse);
      }
    },
  );

  test(
    'a purchase still works for this session when storage is gone',
    () async {
      final features = FeatureEntitlements();

      expect(await features.purchase(AlbumiumFeature.customStickers), isTrue);
      expect(features.isUnlocked(AlbumiumFeature.customStickers), isTrue);
    },
  );
}
