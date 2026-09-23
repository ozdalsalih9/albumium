import 'albumium_entitlements.dart';
import 'error_reporter.dart';
import 'play_billing.dart';

/// Connects the ledgers to Google Play.
///
/// Called without awaiting: reaching the store takes a round trip, and the
/// first frame must not wait for it. Until it answers, the app shows the
/// catalogue's own prices and whatever was bought on this device before.
Future<void> startBilling(AlbumiumEntitlements entitlements) async {
  try {
    final client = PlayBillingClient()..start();
    final covers = PlayCoverPurchaseSource(client);
    final features = PlayFeaturePurchaseSource(client);

    // Prices come from Play, so the user sees their own currency and a price
    // changed in Play Console needs no app update.
    final prices = await client.loadPrices(albumiumProductIds());
    covers.cachePrices(prices);
    features.cachePrices(prices);
    entitlements.covers.useSource(covers);
    entitlements.features.useSource(features);

    // An unreachable store must not be read as "you own nothing", or a lost
    // connection would take away what someone paid for.
    if (prices.isEmpty) return;

    // Play is the truth about ownership: a purchase made on another device
    // appears here, and a refunded one closes again.
    await entitlements.covers.applyStoreOwnership(await covers.restore());
    await entitlements.features.applyStoreOwnership(await features.restore());
  } catch (error, stack) {
    ErrorReporter.report(error, stack, context: 'startBilling');
  }
}
