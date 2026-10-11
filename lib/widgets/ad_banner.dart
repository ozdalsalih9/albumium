import 'package:flutter/material.dart';

/// Builds the banner for a screen, or null where there is none to show.
///
/// The seam that keeps the ad SDK out of the widget tree: the default builds
/// nothing, so no test ever reaches it.
typedef BannerAdBuilder = Widget? Function(BuildContext context);

abstract final class BannerAds {
  /// A listenable, not a plain field: the SDK needs consent and a network
  /// round trip before it can hand over a builder, by which time the screens
  /// have long since been built. Without this they would never hear that the
  /// banner had arrived and would stay empty until an unrelated rebuild.
  static final ValueNotifier<BannerAdBuilder?> builder = ValueNotifier(null);

  static void configure(BannerAdBuilder value) => builder.value = value;

  static void resetForTesting() => builder.value = null;
}

/// A banner beside the navigation bar, on the screens people browse.
///
/// Deliberately absent from the editor: that screen is worked with a finger
/// all over it, and a banner within reach of those taps turns honest use into
/// accidental clicks, which Google counts as invalid traffic and charges to
/// the whole account — both platforms share it.
///
/// It takes no height until an ad has actually loaded, so a screen with no
/// fill keeps its navigation bar where it was instead of leaving a grey strip.
class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BannerAdBuilder?>(
      valueListenable: BannerAds.builder,
      builder: (context, build, _) {
        final banner = build?.call(context);
        if (banner == null) return const SizedBox.shrink();
        return Semantics(
          key: const ValueKey('ad-banner'),
          label: 'Reklam',
          container: true,
          child: banner,
        );
      },
    );
  }
}
