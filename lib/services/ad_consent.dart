/// Lets someone change the ad choice they made earlier.
///
/// Wherever consent is required by law, so is a way to take it back, and it
/// has to live in the app rather than in a settings screen Google owns. This
/// is the seam that keeps the SDK out of the widget, like [RewardedAdSource].
abstract class AdConsentController {
  /// Whether this user was ever asked, and so has something to change.
  ///
  /// False outside the regions where a consent form is shown, which is where
  /// the button would only confuse.
  Future<bool> canChangeChoice();

  /// Reopens the form. Returns an error message when it could not be shown.
  Future<String?> showChoiceForm();
}

/// The controller used until the ad SDK is installed, and in every test.
class NoAdConsentController implements AdConsentController {
  const NoAdConsentController();

  @override
  Future<bool> canChangeChoice() async => false;

  @override
  Future<String?> showChoiceForm() async => null;
}

abstract final class AdConsent {
  static AdConsentController _controller = const NoAdConsentController();

  static AdConsentController get controller => _controller;

  static void configure(AdConsentController value) => _controller = value;

  static void resetForTesting() => _controller = const NoAdConsentController();
}
