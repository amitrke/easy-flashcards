# Releasing

Same pipeline as Voice Notes (itself adapted from `amitrke/relay-player`).

- `.github/workflows/release.yml` builds and ships **test builds** to Google Play internal testing and TestFlight.
- `.github/workflows/promote.yml` sends a tested build to **production** on both stores.
- `.github/workflows/build.yml` makes sideloadable APKs (manual, needs no secrets).
- `fastlane/` holds the production lanes and the store listings (`fastlane/metadata`).

| Trigger | Result |
|---|---|
| push to `develop` | a test build, named `pubspec version (build number)` |
| push of tag `v1.0.0` | a test build of that version; the tag must match `pubspec.yaml`. Releases do not need this |
| manual run of "Release to testers" | same, with a choice of store and Play status |

`main` releases nothing on its own. The build number is `github.run_number + 100` on both stores, so the same
commit has the same number in TestFlight and Play. Never rename or recreate `release.yml`: that restarts the run
number, which the stores reject.

## Rules (checked in the workflow's version step, so they fail in seconds)

- `pubspec.yaml` holds the version being tested. Bump it straight after a release.
- A tag must match it. Once a version's tag exists, test builds of that version stop until pubspec is bumped.
- The version must be `MAJOR.MINOR.PATCH`.

## To release

Production gets the build testers already have. Nothing is rebuilt.

1. Note the build number testers approved: the number in brackets in TestFlight and Play Console (`145` in
   `1.0.1 (145)`).
2. Update release notes: `fastlane/metadata/android/en-US/changelogs/default.txt` (500 characters at most) and
   `fastlane/metadata/ios/en-US/release_notes.txt`, plus any listing text that is out of date.
3. Merge `develop` into `main`.
4. Run **Promote to production** from `main` with action `release` and that build number, then approve it in the
   `production` environment. It promotes the Play build to production, sends the TestFlight build to App Review
   (released automatically once approved), and tags `vX.Y.Z` when every store it covered has succeeded.
5. Bump `pubspec.yaml` on `develop`.

Do not push the tag yourself: it would start `release.yml` and replace the tested build on Play's internal track.

Other `promote.yml` actions: `listing` (upload store text only), `screenshots` (Play screenshots only),
`check` (show how live listings differ from `fastlane/metadata`; changes nothing). All run from `main` only and
wait for approval in the `production` environment. Run `check` before the first `release` or `listing`, because an
upload overwrites whatever text is in the consoles.

To run a lane locally: `bundle install`, then `bundle exec fastlane lanes`. Lanes read `PLAY_JSON_KEY_PATH`,
`ASC_KEY_ID`, `ASC_ISSUER_ID` and `ASC_KEY_PATH`.

Set the repository variable `RELEASE_ANDROID` or `RELEASE_IOS` to `false` to skip a store on every push.

## One-time setup for this app

Done already: the App Store Connect app (Apple ID 6835244766, "Easy Flashcards & Quiz"), the Play Console app, and
the registered bundle ID `com.subnext.basicflashcards` (team `BTSKP77HML`).

### 1. Android upload keystore (new, for this app)

Create a keystore outside the repo and back it up. Losing it means asking Google to reset the upload key.

```bash
keytool -genkeypair -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Keep it in `C:\Users\amitr\dev\keystores\easy-flashcards\`. Never commit it.

### 2. Repository variables

| Name | Value |
|---|---|
| `ANDROID_UPLOAD_KEY_ALIAS` | `upload` |
| `APP_STORE_CONNECT_API_KEY_ID` | the App Store Connect API key's ID (same key as Voice Notes works) |
| `APP_STORE_CONNECT_ISSUER_ID` | the team's issuer ID |

### 3. Repository secrets

| Name | Value |
|---|---|
| `ANDROID_UPLOAD_KEYSTORE_BASE64` | the keystore, base64-encoded |
| `ANDROID_UPLOAD_KEYSTORE_PASSWORD` | its store password |
| `ANDROID_UPLOAD_KEY_PASSWORD` | its key password |
| `APP_STORE_CONNECT_API_KEY_P8` | the whole `.p8` file, including the BEGIN/END lines (Admin role, for cloud signing) |
| `PLAY_SERVICE_ACCOUNT_JSON` | JSON key of the shared Play service account |

The Play service account `play-release@subnext-play-release.iam.gserviceaccount.com` has account-level permissions
covering every app. Give this repo its own key so it can be revoked alone:

```bash
gcloud iam service-accounts keys create key.json \
  --iam-account=play-release@subnext-play-release.iam.gserviceaccount.com \
  --project subnext-play-release
gh secret set PLAY_SERVICE_ACCOUNT_JSON -R amitrke/easy-flashcards < key.json
rm key.json
```

### 4. The `production` environment

Settings, Environments: create `production`, add yourself as a required reviewer (leave "Prevent self-review"
off), and limit it to the `main` branch. That is what stops anything reaching production without approval.

### 5. Android: the first bundle goes up by hand

Play's API cannot create an app's first release. Run "Release to testers" (it keeps the AAB as an artifact even
without Play credentials), download `app-release.aab`, and upload it once in Play Console (Internal testing, Create
new release). After that CI uploads automatically.

### 6. Store forms that must be completed in the consoles

These are not in `fastlane/metadata` and block review: App Privacy (App Store) and the Data safety form (Play),
the content rating questionnaire on both, a privacy policy URL, screenshots and the app icon.

### iOS signing

No certificate or profile is stored. `xcodebuild -allowProvisioningUpdates` with the API key lets Apple manage
them, so the key must have the **Admin** role.

## Notes

- A green iOS job means Apple accepted the upload. Processing then takes 10 to 30 minutes before TestFlight offers
  the build.
- Internal TestFlight testers must be App Store Connect users. Anyone else is an external tester and needs Beta
  App Review.
- Re-running a failed run reuses its build number, so a run that got as far as uploading cannot just be re-run.
