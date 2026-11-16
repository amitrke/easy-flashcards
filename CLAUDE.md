# Easy Flashcards & Quiz: working notes

Flutter app (Android and iOS): study sets, flashcards, quizzes. Sets are stored on the device behind the
`SetRepository` interface (`lib/data/set_repository.dart`); accounts and cloud sync are planned and will be a second
implementation of that interface. See `docs/RELEASING.md` for the release pipeline.

## Branches and releases (same model as amitrke/voice-notes)

- `main` is the default branch. It releases nothing on its own.
- `develop` is the test channel: **pushing to it ships a test build to Play internal testing and TestFlight.**
  Only push there when testers should get the build.
- Work on a feature branch, open a pull request, merge. Do not push work-in-progress to `develop`.
- A release is: merge `develop` into `main`, run the "Promote to production" workflow from `main` with the tested
  build number, then bump `pubspec.yaml` on `develop`. Do not push release tags by hand.
- Store listings and release notes live in `fastlane/metadata`; edit them there, not in the consoles.
- Never rename or recreate `.github/workflows/release.yml`: that restarts the build number, which the stores reject.

## Before pushing

```bash
flutter analyze
flutter test
```

CI pins Flutter 3.47.0 (`FLUTTER_VERSION` in the workflows). Change it in all three workflows together.

## Secrets

Never commit `android/key.properties`, `*.jks`, `.p8` files or API keys. The upload keystore lives in
`C:\Users\amitr\dev\keystores\easy-flashcards\`. CI gets keys only from GitHub secrets, and only `release.yml` and
`promote.yml`. The shared Play service account key can release to production for every app on the account, so a
leak is serious.

## Identifiers

Android package and iOS bundle ID: `com.subnext.basicflashcards` (permanent once published).
Apple team `BTSKP77HML`. Store name "Easy Flashcards & Quiz" on both stores.
App Store Connect Apple ID 6835244766.
