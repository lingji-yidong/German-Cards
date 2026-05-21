# GermanCards

A SwiftUI vocabulary and grammar reference app for German learners. GermanCards keeps a personal word-card library on device, supports spoken German pronunciation through the system speech synthesizer, and runs on iPhone, iPad, and macOS through Mac Catalyst.

## Preview

<table>
  <tr>
    <td width="34%"><img src="docs/images/demo_mobile.png" alt="GermanCards mobile demo" width="220"></td>
    <td width="66%"><img src="docs/images/demo_desktop.png" alt="GermanCards desktop demo" width="420"></td>
  </tr>
</table>

## Highlights

- Build German vocabulary cards with notes, examples, gender, plural forms, and related grammar context.
- Search and review saved cards from a local personal dictionary.
- Listen to German pronunciation using Apple system voices.
- Export and import `GermanCardsDictionary.json` for backup, AirDrop transfer, Git storage, or cloud sync.
- Use the same SwiftUI codebase across iOS, iPadOS, and macOS.

## Platforms

GermanCards supports:

- iPhone and iPad on iOS/iPadOS 18 or later
- macOS 15 or later as a Mac Catalyst app
- Apple silicon and Intel Macs through the GitHub Actions universal macOS package

## macOS Builds

The GitHub Actions workflow builds a universal Mac Catalyst app with both `arm64` and `x86_64` slices. Each run uploads an unsigned artifact named `GermanCards-macOS-universal-unsigned` containing:

- `GermanCards-macOS-universal.pkg` - installer package for `/Applications`
- `GermanCards-macOS-universal.dmg` - drag-and-drop disk image
- `GermanCards-macOS-universal.zip` - zipped `.app` bundle for quick testing

These builds are unsigned and not notarized. On first launch, macOS may require approval from System Settings > Privacy & Security.

## Release Disclaimer

Release builds are provided for convenience only. They are distributed as-is, without warranty, support commitment, or liability for data loss, system issues, security decisions, or any other damage arising from installation or use. Review the source code and build the app yourself if you need stronger trust guarantees.

## Local Development

Open the project in Xcode 16.4 or later:

```bash
open GermanCards.xcodeproj
```

Build from the command line for iOS:

```bash
xcodebuild \
  -project GermanCards.xcodeproj \
  -scheme GermanCards \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Build a universal Mac Catalyst app locally:

```bash
xcodebuild \
  -project GermanCards.xcodeproj \
  -scheme GermanCards \
  -configuration Release \
  -destination 'generic/platform=macOS,variant=Mac Catalyst' \
  ARCHS='arm64 x86_64' \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## App Icon

The app icon is managed through `Assets.xcassets/AppIcon.appiconset`. The Xcode project explicitly sets `CFBundleIconName` to `AppIcon` and enables standalone icon generation so Mac Catalyst builds include the icon assets expected by macOS.

## Signing

Personal signing values stay out of git. For local device installs, copy the example config and add your Apple Developer Team ID:

```bash
cp Config/Signing.example.xcconfig Config/Signing.local.xcconfig
```

`Config/Signing.local.xcconfig` is ignored by git. Do not commit private keys, provisioning profiles, App Store Connect credentials, or personal team identifiers.

## Data Model

GermanCards does not ship a third-party dictionary. Saved cards are stored as the user's own local dictionary and can be exported as `GermanCardsDictionary.json` from Settings.

## License

GermanCards is released under the MIT License. See [LICENSE](LICENSE).
