# iOS Release-Readiness Audit — FC Squad / Random Team Shuffle

**Audit date:** 2026-07-10  
**Scope:** Static repo review + `flutter pub get` on Linux. No code changes. `pod install` / `flutter build ipa` were **not** run (no CocoaPods/macOS in this environment).  
**Codemagic context:** `ios-app-preview` workflow builds simulator debug successfully per project history.

---

## 1. Summary

The iOS project is in **good shape for moving to a signed release pipeline**. The Xcode project is clean for Codemagic automatic signing (no hard-coded team ID or provisioning profile), the bundle ID is consistent across build configurations, dependencies are all cross-platform Flutter plugins with no Android-only packages, and the app does not use camera, location, push, or other APIs that would require `Info.plist` usage-description strings. Simulator debug already builds on Codemagic.

What remains is mostly **release process and polish**, not fundamental iOS breakage: App Store Connect signing integration, first signed `.ipa` build verification, branding/name alignment across the store listing and on-device labels, a custom launch screen (currently the Flutter default), and iPad-specific store assets and share-sheet behavior because the Xcode target ships as a universal app. There are **no obvious App Store rejection blockers in native iOS configuration** based on this audit, but the first device-signed build and TestFlight upload have not yet been proven in CI.

---

## 2. Blocking issues

Listed in priority order. “Blocking” here means likely to break a signed build, cause App Store rejection, or cause a serious runtime failure on iOS.

| Priority | Issue | Why it matters |
|----------|--------|----------------|
| **P0** | **Signed release build not yet validated** | Only `flutter build ios --simulator --debug` is configured in `codemagic.yaml`. `flutter build ipa --release` with `distribution_type: app_store` signing has not been run in this repo audit environment. First signed build may surface CocoaPods or export issues. |
| **P1** | **Apple API key committed to repo root** | `AuthKey_L4SBNLBT3H.p8` is present as an untracked file in the project root. If ever committed, this is a credential leak. Rotate the key if it was exposed. Not an iOS build config issue, but blocks safe release hygiene. |
| **P2** | **iPad share sheet may fail without `sharePositionOrigin`** | `ResultsScreen._shareResults()` calls `SharePlus.instance.share(ShareParams(text: ...))` with no `sharePositionOrigin`. On iPad, `UIActivityViewController` typically requires a popover anchor; this can crash or no-op. App targets iPad (`TARGETED_DEVICE_FAMILY = "1,2"`). |

**Note:** Missing `Info.plist` privacy usage strings is **not** a blocker for this app — no permission-requiring APIs were found in `lib/`.

---

## 3. Non-blocking gaps

| Gap | Detail |
|-----|--------|
| **Launch screen is stock Flutter placeholder** | `LaunchScreen.storyboard` uses centered `LaunchImage` on a **white** background. `LaunchImage*.png` files are ~68 bytes (empty/placeholder). Users see a white flash before the dark-themed app loads. |
| **Branding inconsistency** | On-device / store-adjacent names differ: **Random Team Shuffle** (iOS `Info.plist`, Android label, `MaterialApp.title`), **FC Squad** (`PRIVACY_POLICY.md`), **fc_squad** (`pubspec.yaml` package name), repo folder **FCSquad**. |
| **No `ios/Podfile` committed** | `ios/Podfile` is absent from the repo. Flutter generates it on `flutter build ios` / `flutter pub get` + build. Codemagic simulator builds imply this works at CI time. Committing a Podfile is optional but improves reproducibility. |
| **`ios/Podfile` platform line not auditable** | Without a committed Podfile or a macOS `pod install` run, cannot confirm `platform :ios` matches `IPHONEOS_DEPLOYMENT_TARGET = 13.0`. Flutter 3.38.x typically aligns these automatically. |
| **No app-level `PrivacyInfo.xcprivacy`** | No `PrivacyInfo.xcprivacy` in `ios/Runner/`. Transitive plugins (`path_provider_foundation`, etc.) may ship their own manifests inside CocoaPods artifacts at build time. App-level manifest may still be needed if you add APIs directly later. |
| **Google Fonts network usage** | `google_fonts` downloads Montserrat at runtime (HTTPS). No `Info.plist` key required, but App Store Connect **App Privacy** questionnaire must accurately describe third-party font fetching (not user PII, but network to Google). |
| **iPad App Store screenshots required** | Universal app (`TARGETED_DEVICE_FAMILY = "1,2"`). If you distribute on iPad, Apple expects iPad screenshot sizes in addition to iPhone. |
| **Runner Xcode target has no explicit `CODE_SIGN_STYLE`** | Only `RunnerTests` sets `CODE_SIGN_STYLE = Automatic`. Runner relies on Xcode defaults; Codemagic `xcode-project use-profiles` is expected to apply profiles. Not a conflict, but worth monitoring on first signed build. |
| **`CODE_SIGN_IDENTITY` still says `iPhone Developer` at project level** | Project-wide Debug/Release/Profile use `"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer"`. Codemagic typically overrides for distribution builds; verify on first `app_store` IPA. |
| **Privacy policy wording vs iOS reality** | Policy mentions “Storage/Media” permission; iOS has no Android-style storage permission. Share uses system sheet only. Policy should be reviewed for iOS accuracy before submission. |
| **No `integration_test` / screenshot automation yet** | Planned for release pipeline; not present today. |
| **`AuthKey_*.p8` not in `.gitignore`** | `.gitignore` has no `*.p8` rule. |

---

## 4. Open questions for you

1. **App Store display name** — Should the customer-facing name be **Random Team Shuffle**, **FC Squad**, or something else? It currently shows **Random Team Shuffle** on iOS home screen (`CFBundleDisplayName`) but the privacy policy says **FC Squad**.

2. **iPad distribution** — Xcode enables iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,2"`). Do you want to:
   - Ship as a **universal** app (requires iPad screenshots + iPad QA, including share), or
   - Restrict to **iPhone only** (`TARGETED_DEVICE_FAMILY = 1`) to reduce store asset burden?

3. **Launch screen design** — Is the white Flutter default acceptable for v1, or do you want a branded dark splash matching `AppColors.backgroundDark` before release?

4. **App Store Connect privacy answers** — Will you declare **no data collection** / local-only, while acknowledging Google Fonts may contact Google’s servers for font files? Apple reviewers compare privacy labels to behavior.

5. **TestFlight scope** — Internal testers only first, or external beta? (Affects export options like `testFlightInternalTestingOnly`.)

6. **Bundle ID confirmation** — Repo uses `com.ecslab.fcsquad`. Does this exactly match your App Store Connect app record?

7. **Rotate API key?** — `AuthKey_L4SBNLBT3H.p8` sits in the repo working tree. Has this key only been uploaded to Codemagic, or should it be rotated?

---

## 5. Section-by-section findings

### 5.1 Bundle identifier & project identity

| Item | Finding |
|------|---------|
| **Bundle ID** | `com.ecslab.fcsquad` |
| **Debug** | `PRODUCT_BUNDLE_IDENTIFIER = com.ecslab.fcsquad` (`project.pbxproj` line ~550) |
| **Release** | `com.ecslab.fcsquad` (~572) |
| **Profile** | `com.ecslab.fcsquad` (~371) |
| **RunnerTests** | `com.ecslab.fcsquad.RunnerTests` (test target only; separate from app ID) |
| **Android parity** | `applicationId = "com.ecslab.fcsquad"` in `android/app/build.gradle.kts` — matches iOS |
| **Display name (`Info.plist`)** | `CFBundleDisplayName` = **Random Team Shuffle** |
| **Bundle name (`Info.plist`)** | `CFBundleName` = **Random Team Shuffle** |
| **Versioning** | `CFBundleShortVersionString` → `$(FLUTTER_BUILD_NAME)`; `CFBundleVersion` → `$(FLUTTER_BUILD_NUMBER)`; `pubspec.yaml` = `1.0.0+16` |

**Assessment:** Bundle ID is **consistent** across Debug, Release, and Profile. Display name is consistent between iOS and Android labels but **may not match** your intended App Store marketing name or privacy policy branding — confirm with open question #1.

---

### 5.2 Deployment target & Xcode project health

| Item | Value / status |
|------|----------------|
| **`IPHONEOS_DEPLOYMENT_TARGET`** | **13.0** (project-level Debug, Release, Profile) |
| **`MinimumOSVersion` in `AppFrameworkInfo.plist`** | **13.0** — aligned |
| **Flutter version (Codemagic / local)** | **3.38.4** (stable) |
| **`TARGETED_DEVICE_FAMILY`** | **"1,2"** (iPhone + iPad) |
| **`ios/Podfile`** | **Not present** in repo (Flutter-generated at build time) |
| **`pod install` in this audit** | **Not run** — CocoaPods not available on Linux audit host |

**Plugin minimum iOS (inferred from pub.dev / lockfile, not pod install):**

| Dependency | iOS support | Typical minimum iOS |
|------------|-------------|---------------------|
| `hive_flutter` / `path_provider` | Yes | iOS 12+ |
| `share_plus` 12.x | Yes | iOS 12+ |
| `google_fonts` 8.x | Yes | iOS 12+ |
| `flutter_slidable` 4.x | Yes | iOS 11+ |
| `flutter_riverpod` | Yes | N/A (Dart) |

**Assessment:** Deployment target **13.0** is compatible with Flutter 3.38.4 and all declared plugins. No known plugin forces iOS 14+ that would conflict. **Cannot confirm** Podfile `platform :ios` line or post-`pod install` warnings without a macOS build log — recommend watching the first Codemagic signed build for CocoaPods deprecations.

**Codemagic note:** Current workflow runs `flutter pub get` + `flutter build ios --simulator --debug` only — no explicit `pod install` step. Flutter’s iOS build invokes CocoaPods internally when needed.

---

### 5.3 Info.plist completeness

#### Permission-requiring APIs scanned in `lib/` and `pubspec.yaml`

| API / plugin | Used? | Matching `Info.plist` key needed? |
|--------------|-------|-----------------------------------|
| Camera | No | — |
| Photo library | No | — |
| Microphone | No | — |
| Location | No | — |
| Contacts | No | — |
| Push notifications | No | — |
| Bluetooth | No | — |
| Calendar / Reminders | No | — |
| Face ID | No | — |
| Local network / Bonjour | No | — |
| `share_plus` (system share sheet) | Yes | No usage description required |
| `google_fonts` (HTTPS download) | Yes | No usage description required |
| `hive_flutter` (app documents dir) | Yes | No usage description required |

**Missing `NS*UsageDescription` keys:** **None required** for current functionality.

#### Required / standard keys present

| Key | Status |
|-----|--------|
| `CFBundleDisplayName` | Present — "Random Team Shuffle" |
| `CFBundleShortVersionString` | Present — `$(FLUTTER_BUILD_NAME)` |
| `CFBundleVersion` | Present — `$(FLUTTER_BUILD_NUMBER)` |
| `UILaunchStoryboardName` | Present — `LaunchScreen` |
| `CFBundleIdentifier` | Present — `$(PRODUCT_BUNDLE_IDENTIFIER)` |
| `LSRequiresIPhoneOS` | Present — `true` |

**Also present:** Portrait + landscape orientations (iPhone and iPad), `CADisableMinimumFrameDurationOnPhone`, `UIApplicationSupportsIndirectInputEvents`.

**Not present (and not needed today):** `NSAppTransportSecurity` exceptions, `UIBackgroundModes`, `ITSAppUsesNonExemptEncryption` export compliance flag (you’ll answer encryption questions in App Store Connect manually).

---

### 5.4 Signing & entitlements groundwork

| Check | Finding |
|-------|---------|
| **`DEVELOPMENT_TEAM`** | **Not set** anywhere in `project.pbxproj` — good for Codemagic auto-signing |
| **`PROVISIONING_PROFILE` / UUID** | **Not set** — good |
| **Manual profile name** | **None** |
| **`CODE_SIGN_STYLE`** | Set to **Automatic** only on **RunnerTests** target; Runner target has no explicit style |
| **`ios/Runner/Runner.entitlements`** | **Does not exist** |
| **Capabilities in Xcode project** | No Push, Associated Domains, App Groups, iCloud, Keychain Sharing, or Background Modes configured |
| **Android-only capabilities** | Android manifest only declares `INTERNET` + standard Flutter activity. No background location, FCM, or dangerous permissions. **No Android capability lacks an iOS equivalent** for this app. |

**Assessment:** Project is **compatible with Codemagic `ios_signing` + `distribution_type: app_store`** without manual signing conflicts. No entitlements file means no capability mismatches — app is a standard local-storage utility with share sheet.

---

### 5.5 Platform-specific code paths

#### `Platform.isIOS` / `Platform.isAndroid` usage

| Location | Behavior on iOS |
|----------|-----------------|
| `lib/utils/platform_ui.dart` | `isIOS` / `isCupertino` gates UI chrome: Cupertino routes, tab bar, dialogs, action sheets, scaffolds, buttons |
| `lib/main.dart` | Wraps app in `CupertinoTheme` when `PlatformUi.isCupertino` |
| `lib/screens/main_navigation_screen.dart` | Uses `CupertinoTabBar` instead of `BottomNavigationBar`; skips Android double-back-to-exit `PopScope` |
| `lib/screens/*.dart` (multiple) | Cupertino back buttons, confirm dialogs, platform icons — **intentional iOS adaptations** |

**No `Platform.isAndroid` branches** found in `lib/`. Android-specific behavior is the default Material path when not on iOS.

#### Plugin platform support (`pubspec.yaml` direct dependencies)

| Package | iOS | Notes |
|---------|-----|-------|
| `flutter_riverpod` | Yes | Pure Dart |
| `google_fonts` | Yes | Runtime font download |
| `uuid` | Yes | Pure Dart |
| `flutter_slidable` | Yes | |
| `hive` / `hive_flutter` | Yes | Via `path_provider_foundation` |
| `share_plus` | Yes | See iPad `sharePositionOrigin` gap |
| `intl` | Yes | Pure Dart |
| `cupertino_icons` | Yes | |

**No Android-only direct dependencies.**

#### Hardcoded paths / MethodChannels

| Check | Finding |
|-------|---------|
| Hardcoded `/data/` or Android storage paths | **None** |
| Custom `MethodChannel` in `lib/` | **None** |
| Storage | `Hive.initFlutter()` — platform documents directory via plugin |
| Native iOS code | Stock `AppDelegate.swift` only — registers `GeneratedPluginRegistrant` |

---

### 5.6 Assets, icons, and launch screen

#### App icons (`ios/Runner/Assets.xcassets/AppIcon.appiconset`)

| Check | Status |
|-------|--------|
| iPhone sizes (20–60pt @2x/@3x) | **Present** |
| iPad sizes (20–83.5pt) | **Present** |
| App Store marketing 1024×1024 | **Present** — `ItunesArtwork@2x.png` verified **1024×1024** PNG |
| Source | `Contents.json` author: **easyappicon**; matching assets also under `assets/easyappicon-icons-*/` |
| `flutter_launcher_icons` | In `dev_dependencies` but **no `flutter_launcher_icons:` config** in `pubspec.yaml` — icons appear manually installed |

**Minor quirk:** `Contents.json` includes an iPhone idiom entry for 76×76@2x (normally iPad-only). File exists; unlikely to block submission.

#### Launch screen

| Check | Status |
|-------|--------|
| `LaunchScreen.storyboard` | Present — **default Flutter template** |
| Background | **White** (`red/green/blue = 1`) — mismatches app dark theme |
| `LaunchImage` assets | **Placeholder** (~68-byte PNGs); not branded artwork |
| `LaunchImage.imageset` | Referenced but images are effectively empty |

**Assessment:** Icons are **release-ready**. Launch screen is **functional but unpolished** — not a rejection risk, but visible on every cold start.

---

### 5.7 Build & dependency sanity

#### `pubspec.yaml` / lockfile notes

- **SDK:** `^3.10.3` — matches local Dart 3.10.3 from Flutter 3.38.4.
- **`flutter pub get`:** Succeeded in audit environment.
- **No obvious version pins** known to break iOS pods (no Firebase, no conflicting native SDKs).
- **Dev-only tools** (`build_runner`, `hive_generator`, `flutter_launcher_icons`) do not affect release iOS binaries.

#### Flutter-generated iOS files

| File | Status |
|------|--------|
| `ios/Flutter/Generated.xcconfig` | Listed in `ios/.gitignore` — **correct**; generated locally by `flutter pub get`, not committed |
| `ios/Flutter/ephemeral/` | Gitignored — correct |
| `ios/Runner/GeneratedPluginRegistrant.*` | Gitignored — correct |
| `ios/Pods/` | Gitignored — correct |
| `Debug.xcconfig` / `Release.xcconfig` | Only `#include "Generated.xcconfig"` — **not manually corrupted** |

**Assessment:** Fresh Codemagic checkout will regenerate Flutter iOS artifacts correctly. No committed stale `Generated.xcconfig` to break CI.

#### What was not run

- `pod install` / `pod update`
- `flutter build ipa`
- `flutter analyze` (not part of this audit)

---

### 5.8 App Store Connect metadata gaps (code-adjacent)

#### Privacy manifest (`PrivacyInfo.xcprivacy`)

| Item | Finding |
|------|---------|
| App-level manifest in `ios/Runner/` | **Absent** |
| Direct use of Apple “required reason” APIs in app Dart code | **Not detected** (no file timestamp APIs, disk space APIs, etc. in app code) |
| Transitive plugins | `path_provider_foundation`, `share_plus`, and other pods typically embed privacy manifests in their pod bundles when built — **verify in first IPA build artifact** |

#### App Tracking Transparency (ATT)

| Check | Finding |
|-------|---------|
| Analytics SDKs (Firebase Analytics, Facebook, etc.) | **None** |
| Ad SDKs | **None** |
| `NSUserTrackingUsageDescription` | **Not present** — correct for current stack |
| `google_fonts` | Fetches font files; **not** user tracking — ATT not required |

#### Other store-adjacent code items

| Item | Finding |
|------|---------|
| **Encryption export** | No `ITSAppUsesNonExemptEncryption` in `Info.plist` — answer in App Store Connect (likely exempt standard HTTPS) |
| **Privacy policy URL** | `PRIVACY_POLICY.md` exists in repo; ensure hosted URL is entered in ASC |
| **User-generated content** | Player names entered locally — no moderation infrastructure (store questionnaire item, not code) |
| **Age rating** | Sports/utility app with local data — likely low rating; your ASC questionnaire |

#### Codemagic CI state

Current `codemagic.yaml` contains only **`ios-app-preview`** (simulator debug). No signed IPA, TestFlight publishing, or screenshot workflows yet — expected pre-release state.

---

## Appendix: Quick reference

```
Bundle ID:     com.ecslab.fcsquad
Display name:  Random Team Shuffle
Version:       1.0.0 (build 16)
Min iOS:       13.0
Devices:       iPhone + iPad (universal)
Entitlements:  None
Permissions:   None required in Info.plist today
Signing:       Clean for Codemagic automatic app_store signing
```

---

*End of audit. No other repository files were modified.*
