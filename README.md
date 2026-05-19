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
