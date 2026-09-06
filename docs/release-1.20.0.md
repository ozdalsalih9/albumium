# Albumium 1.20.0 (31)

- Based on main commit 499e35d; preserves the new scrollable binding picker.
- Four-step first-launch introduction in Turkish and English, with persistent completion and deferred incoming album navigation.
- Contextual gallery explanation and Android system photo picker, without broad media/storage permissions. Selection cancellation, errors and repeated taps are handled.
- Privacy policy link on the home page and final introduction step.
- Release signing uses android/key.properties and android/upload-keystore.jks. Both are ignored by Git: securely back up both files. Never regenerate the upload key for an update.
- Build: flutter build appbundle --release. No debug-key fallback.

Verification: flutter analyze passed; the initial 26 focused tests passed. The full suite found five home-library tests that still entered onboarding; their setup was updated to explicitly bypass onboarding. At the user's request, tests were not rerun after that update. No Android device or AVD was available for native permission/browser checks. The supplied privacy-policy URL could not be independently opened by the web tool; check it in a signed-out browser before submission.

System picker selection grants access only to selected files; a broad Android permission popup is intentionally not requested. No camera, microphone, location or notification permissions are needed by the current features.
