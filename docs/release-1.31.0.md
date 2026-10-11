# Albumium 1.31.0 (56)

Android carries a banner ad for the first time. It sits directly above the
navigation bar on the album, theme and card tabs, and nowhere else. The editor,
the preview, the card studio and the video screen have none: those screens are
worked with a finger all over them, and an ad within reach of those taps turns
honest use into accidental clicks, which Google counts as invalid traffic and
charges back against the whole account.

The strip is sized to the ad inside it, with a ceiling of 80 logical pixels. A
short ad takes a short strip instead of sitting centred in a tall box with app
background showing above and below it. It takes no height at all until an ad
has actually loaded, so a screen with no fill looks exactly as it did before.

The navigation bar goes from Material's 80 to 68 logical pixels. The icons keep
well over the 48 a finger needs, and the band of empty surface above them is
given back to the page.

The purchases are unchanged: Android still sells its covers, its custom
stickers and its Full HD export, and the rewarded ad for one Full HD export is
still there. The banner is the only addition.

The privacy policy on albumiumapp.com now describes the banner and states that
in-app purchases exist on Android only.

iOS, which sells nothing and runs on ads alone, shares all of this code and
additionally carries full-screen ads at the editor and preview exits. That part
ships on its own schedule.

Release builds must pass `--dart-define=ALBUMIUM_LIVE_ADS=true`, or the app
requests Google's test units and earns nothing.

Android release outputs use version name 1.31.0 and version code 56.

Validation: Flutter analysis passed with no issues. All 417 tests passed,
including new ones holding the banner above the navigation bar on both
platforms, on every tab, and one that fails if the banner stops noticing that
the ad SDK has finished starting.
