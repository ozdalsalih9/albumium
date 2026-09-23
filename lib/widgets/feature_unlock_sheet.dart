import 'package:flutter/material.dart';

import '../l10n/albumium_localizations.dart';
import '../services/albumium_entitlements.dart';
import '../services/feature_entitlements.dart';
import '../services/rewarded_ads.dart';
import '../theme/albumium_app_theme.dart';

/// Offers a paid feature, by ad or by purchase. Returns true once the user may
/// go ahead.
///
/// Watching an ad earns a single use; buying keeps it. The sheet is the only
/// place that difference is explained, so both buttons say what they give.
Future<bool> showFeatureUnlockSheet(
  BuildContext context, {
  required AlbumiumFeature feature,
  required String title,
  required String description,
  required List<(IconData, String)> bullets,
  FeatureEntitlements? entitlements,
  RewardedAdSource? ads,
  bool offerAd = false,
}) async {
  final unlocked = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _FeatureUnlockSheet(
      feature: feature,
      title: title,
      description: description,
      bullets: bullets,
      entitlements: entitlements ?? AlbumiumEntitlements.instance.features,
      ads: ads ?? RewardedAds.source,
      offerAd: offerAd,
    ),
  );
  return unlocked ?? false;
}

/// Opens the purchase sheet unless custom stickers are already unlocked.
Future<bool> ensureCustomStickers(
  BuildContext context, {
  FeatureEntitlements? entitlements,
}) async {
  final features = entitlements ?? AlbumiumEntitlements.instance.features;
  if (features.isUnlocked(AlbumiumFeature.customStickers)) return true;
  if (!context.mounted) return false;
  return showFeatureUnlockSheet(
    context,
    feature: AlbumiumFeature.customStickers,
    entitlements: features,
    title: 'İstediğin stickerları yap',
    description:
        'Kendi fotoğraflarını kesip albümlerinde kullanacağın stickerlara '
        'dönüştür.',
    bullets: const [
      (Icons.auto_fix_high_outlined, 'İstediğin kadar sticker oluştur.'),
      (Icons.sell_outlined, 'Tek seferlik satın alma.'),
      (Icons.collections_bookmark_outlined, 'Tüm albümlerinde kullan.'),
    ],
  );
}

class _FeatureUnlockSheet extends StatefulWidget {
  const _FeatureUnlockSheet({
    required this.feature,
    required this.title,
    required this.description,
    required this.bullets,
    required this.entitlements,
    required this.ads,
    required this.offerAd,
  });

  final AlbumiumFeature feature;
  final String title;
  final String description;
  final List<(IconData, String)> bullets;
  final FeatureEntitlements entitlements;
  final RewardedAdSource ads;
  final bool offerAd;

  @override
  State<_FeatureUnlockSheet> createState() => _FeatureUnlockSheetState();
}

class _FeatureUnlockSheetState extends State<_FeatureUnlockSheet> {
  bool _working = false;
  bool _adsExhausted = false;
  String? _error;

  /// Runs one action, guarding against a second tap while it is in flight,
  /// and reports failure in that action's own words.
  Future<void> _run(Future<bool> Function() action, String failure) async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    final unlocked = await action();
    if (!mounted) return;
    if (unlocked) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _working = false;
      _error = context.tr(failure);
    });
  }

  Future<void> _watchAd() async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    final outcome = await widget.ads.show(widget.feature);
    if (!mounted) return;
    if (outcome == RewardedAdOutcome.earned) {
      widget.entitlements.grant(widget.feature);
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _working = false;
      // No ad to show is not the user's mistake, so the button stops offering
      // something that will not arrive and the purchase stays open.
      _adsExhausted = outcome == RewardedAdOutcome.unavailable;
      _error = context.tr(switch (outcome) {
        RewardedAdOutcome.dismissed =>
          'Ödülü kazanmak için reklamı sonuna kadar izlemelisin.',
        RewardedAdOutcome.unavailable =>
          'Şu anda gösterilecek reklam yok. Satın alarak hemen açabilirsin.',
        _ => 'Reklam açılamadı. Tekrar deneyebilirsin.',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final price = widget.entitlements.priceLabelFor(widget.feature);

    Widget bullet(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr(text))),
        ],
      ),
    );

    return SafeArea(
      key: const ValueKey('feature-unlock-sheet'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(widget.title),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(widget.description),
              style: TextStyle(color: colors.mutedText, height: 1.4),
            ),
            const SizedBox(height: 18),
            for (final (icon, text) in widget.bullets) bullet(icon, text),
            if (_error != null)
              Padding(
                key: const ValueKey('feature-unlock-error'),
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 6),
            if (widget.offerAd)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('feature-unlock-watch-ad'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: _working || _adsExhausted ? null : _watchAd,
                  icon: _working
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_circle_outline_rounded),
                  label: Text(context.tr('Reklam izle, bir kez kullan')),
                ),
              ),
            if (widget.offerAd) const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: widget.offerAd
                  ? OutlinedButton.icon(
                      key: const ValueKey('feature-unlock-buy'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _working ? null : _buy,
                      icon: const Icon(Icons.lock_open_rounded),
                      label: Text(
                        context.tr(
                          '{price} · Kalıcı aç',
                          values: {'price': price},
                        ),
                      ),
                    )
                  : FilledButton.icon(
                      key: const ValueKey('feature-unlock-buy'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _working ? null : _buy,
                      icon: _working
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_open_rounded),
                      label: Text(
                        context.tr(
                          '{price} · Satın al',
                          values: {'price': price},
                        ),
                      ),
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const ValueKey('feature-unlock-restore'),
                onPressed: _working
                    ? null
                    : () => _run(() async {
                        await widget.entitlements.restore();
                        return widget.entitlements.isUnlocked(widget.feature);
                      }, 'Geri yüklenecek satın alma bulunamadı.'),
                child: Text(context.tr('Satın alımları geri yükle')),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _working ? null : () => Navigator.pop(context),
                child: Text(context.tr('Vazgeç')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _buy() => _run(
    () => widget.entitlements.purchase(widget.feature),
    'Satın alma tamamlanamadı. Tekrar deneyebilirsin.',
  );
}
