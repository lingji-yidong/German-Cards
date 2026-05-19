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
