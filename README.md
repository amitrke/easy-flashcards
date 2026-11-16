# Easy Flashcards & Quiz

A flashcard and quiz app for studying: create study sets, flip through cards, and test yourself.
Built with Flutter (Android and iOS).

- Store name (App Store and Play): Easy Flashcards & Quiz
- Bundle ID / package name: `com.subnext.basicflashcards`

## What works now

- Create, edit and delete study sets (a title plus terms and definitions).
- Flashcards: tap to flip, mark "Got it" or "Still learning", then re-study just the missed cards.
- Quizzes: multiple choice and written questions, with a results screen and the answers to review.
- Everything is saved on the device.

Planned: accounts and cloud sync (a second `SetRepository` implementation), matching and test modes.

## Develop

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Releases (test builds to TestFlight and Play internal testing, then production) are described in
[docs/RELEASING.md](docs/RELEASING.md).
