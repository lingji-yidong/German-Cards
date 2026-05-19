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


## FreeDict Reference

The app loads `Resources/freedict_deu_eng_subset.json` before falling back to curated cards and LLM generation. Regenerate the bundled subset from FreeDict TEI source with:

```bash
python3 Scripts/import_freedict.py
```

The FreeDict deu-eng source is a GPLv3/AGPLv3 mixed work. Keep the license implications in mind before distributing builds.


## Local Signing

Personal signing values are kept out of git. For local iPhone installs, copy the example file and edit your team ID:

```bash
cp Config/Signing.example.xcconfig Config/Signing.local.xcconfig
```

`Config/Signing.local.xcconfig` is ignored by git. Do not put private keys, provisioning profiles, or App Store Connect credentials in tracked files.
