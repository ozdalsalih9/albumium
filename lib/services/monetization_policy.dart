import 'package:flutter/foundation.dart';

/// iOS earns one use per rewarded ad. Android keeps its store and ad offers.
abstract final class MonetizationPolicy {
  static bool get rewardedOnly =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
