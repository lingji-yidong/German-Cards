# GermanCards

SwiftUI iOS app for German vocabulary cards and grammar references.

## CI Build

This repo builds on GitHub Actions with `macos-15` and Xcode 16.x:

```bash
xcodebuild \
  -project GermanCards.xcodeproj \
  -scheme GermanCards \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

The CI build disables code signing, so it verifies compilation but does not create an installable App Store archive.



## User Dictionary

GermanCards does not ship a third-party dictionary. Generated cards are stored as the user's own dictionary. On devices where iCloud Drive is available for the app, the dictionary is mirrored to `GermanCardsDictionary.json` in the app's iCloud documents container.


## Local Signing

Personal signing values are kept out of git. For local iPhone installs, copy the example file and edit your team ID:

```bash
cp Config/Signing.example.xcconfig Config/Signing.local.xcconfig
```

`Config/Signing.local.xcconfig` is ignored by git. Do not put private keys, provisioning profiles, or App Store Connect credentials in tracked files.
