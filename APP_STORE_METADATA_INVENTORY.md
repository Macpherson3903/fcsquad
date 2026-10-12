# App Store Metadata Inventory

Factual findings from static code review of the FCSquad / **Random Team Shuffle** Flutter app. Generated for App Store Connect privacy and age-rating questionnaires. No recommendations on how to answer Apple — only what the code does.

**Review date:** 2026-07-22  
**App version in repo:** `1.0.0+17` (`pubspec.yaml` line 20)  
**Bundle ID:** `com.ecslab.fcsquad` (iOS project)  
**Display name:** Random Team Shuffle (`ios/Runner/Info.plist` lines 7–8, 15–16)

---

## A. Core features

Navigation is a three-tab shell (`lib/screens/main_navigation_screen.dart` lines 28–32, 144–181):

| Tab label | Screen | Primary purpose |
|-----------|--------|-----------------|
| **MY SQUAD** | `MySquadScreen` | Manage the current player roster |
| **GENERATE** | `GenerateScreen` | Paste/import names and start team generation |
| **STATS** | `VaultHistoryScreen` | View and edit all-time player statistics |

### MY SQUAD (`lib/screens/my_squad_screen.dart`)

- Displays total player count and roster grouped by position (DEF / MID / FWD) (`lines 79–130`, `366–411`).
- Search by player name or grade (`lines 59–68`, `280–334`).
- Filter chips: ALL, DEF, MID, FWD (`lines 199–234`).
- Add player via FAB → dialog for name, jersey number, primary position (`lines 346–352`, `563–737`). New players get a UUID (`uuid` package, line 643).
- Edit player → navigates to `UpdatePlayerScreen` (`lines 462–466`).
- Delete individual players with confirmation (`lines 468–481`).
- Clear entire current squad with confirmation; copy states history and all-time stats are **not** affected (`lines 246–258`).
- Shortcut to GENERATE tab when no latest match result exists (`lines 131–188`).

### GENERATE (`lib/screens/generate_screen.dart`)

- Free-text area to paste a squad list; parser strips bullets/numbering (`lines 51–63`, `106–147`).
- Preview of parsed names (`lines 149–156`).
- Bottom panel (when names parsed): choose number of teams (2–8) (`lines 213–229`).
- Button navigates to `RoleSelectionScreen` with pasted names, or uses saved roster if no paste (`lines 233–255`).
- History icon opens `MatchHistoryScreen` (`lines 81–88`).

### Role selection (`lib/screens/role_selection_screen.dart`)

- Per-player position (DEF/MID/FWD) and optional fixed team assignment or AUTO (`lines 295–376`).
- Team generation via `TeamBalancer.generateTeams()` (`lib/services/team_balancer.dart`, called at `role_selection_screen.dart` lines 78–82).
- Positional balance validation with optional “generate anyway” override (`lines 135–261`).
- On success: saves merged roster, auto-saves match to history, sets latest result, navigates to `ResultsScreen` (`lines 97–134`).

### Results (`lib/screens/results_screen.dart`)

- Shows generated teams as colored roster cards (`lines 166–247`).
- Share button builds plain-text team list and invokes system share sheet via `share_plus` (`lines 249–274`). No `sharePositionOrigin` set.
- Can be opened from match history with `existingHistory` (`lines 13–14`, `match_history_screen.dart` line 129).

### Match history (`lib/screens/match_history_screen.dart`)

- Lists saved matches (date, team count, player count) sorted newest first (`lines 31–44`, `86–89`).
- Tap opens `ResultsScreen` for that match (`line 129`).
- Swipe-to-delete match records (`lines 95–122`).

### STATS / Vault (`lib/screens/vault_history_screen.dart`)

- Lists all-time stats per player name: goals, assists, clean sheets (`lines 154–165`).
- Sorted by goals then assists (`lib/providers/all_time_stats_provider.dart` lines 38–41).
- Add new stat entry manually (`lines 235–245`).
- Update stats via stepper dialog (`lines 201–233`).
- Swipe-to-delete stat records (`lines 96–117`).

### Update player (`lib/screens/update_player_screen.dart`)

- Edit name, jersey number, positions, team assignment (`lines 42–49`).

### App entry (`lib/main.dart`)

- Initializes Hive local storage asynchronously via `storageInitializerProvider` (`lines 22–28`, `lib/providers/storage_provider.dart`).
- No login screen, no onboarding flow, no settings screen in `lib/`.

### Team balancing logic (`lib/services/team_balancer.dart`)

- Local algorithm only: splits players by primary position into N teams, respects manual team locks, uses `Random` for shuffle (`lines 11–59+`). No server involvement.

---

## B. Data collected or accessed

### Device permissions (Info.plist / Android manifest)

| Permission / capability | iOS (`ios/Runner/Info.plist`) | Android (`android/app/src/main/AndroidManifest.xml`) |
|-------------------------|-------------------------------|------------------------------------------------------|
| **Contacts** | No `NSContactsUsageDescription` or related key | Not declared |
| **Location** | No `NSLocation*UsageDescription` keys | Not declared |
| **Camera** | No `NSCameraUsageDescription` | Not declared |
| **Microphone** | No `NSMicrophoneUsageDescription` | Not declared |
| **Photo library** | No `NSPhotoLibrary*UsageDescription` keys | Not declared |
| **Internet** | Not declared in Info.plist (not required for outbound HTTPS) | `android.permission.INTERNET` (line 2) |

No permission-requesting plugin usage found in `lib/` (no `permission_handler`, `image_picker`, `geolocator`, etc. in `pubspec.yaml`).

### Analytics SDK

- **No** — No Firebase Analytics, Mixpanel, Amplitude, or similar in `pubspec.yaml` dependencies or `lib/` initialization code.

### Advertising SDK

- **No** — No AdMob, Facebook Audience Network, or ad-related packages in `pubspec.yaml` or `lib/`.

### Crash reporting

- **No** — No Crashlytics, Sentry, or Firebase Crashlytics in `pubspec.yaml` or `lib/`.

### User account / authentication

- **No** — No sign-in, email, social login, or anonymous auth SDK. No backend API calls from `lib/`.
- Player UUIDs are generated locally (`uuid` package, e.g. `my_squad_screen.dart` line 643) and stored in Hive; not transmitted by app code.

### Network calls to third-party domains

**In app Dart code (`lib/`):** No `http.get`, `http.post`, `Dio`, `Uri.parse('https://...')`, or `url_launcher` usage found.

**Via dependencies (not direct app code):**

| Source | Behavior | Domains (from package behavior; not hardcoded in app) |
|--------|----------|--------------------------------------------------------|
| `google_fonts` | `GoogleFonts.montserratTextTheme()` in `lib/theme/app_theme.dart` line 66; `GoogleFonts.montserrat()` in `lib/widgets/stat_panel.dart` line 53 | Typically `fonts.googleapis.com` and `fonts.gstatic.com` when font is not cached. Exact URLs are inside the `google_fonts` package, not this repo. |
| `share_plus` | User-initiated share of text (`results_screen.dart` line 274) | Uses OS share sheet; destination app/service chosen by user. No fixed third-party domain in app code. |

**Cannot determine from static code alone:** Whether `google_fonts` has already cached Montserrat on device (would skip network on subsequent launches).

### Local storage

**Engine:** Hive (`hive`, `hive_flutter`) — `lib/storage/hive_storage.dart`, initialized in `lib/providers/storage_provider.dart`.

| Hive box name | Contents | Key fields / notes |
|---------------|----------|-------------------|
| `players` | Current roster `Player` objects | `id`, `name`, `country`, `grade`, `positions`, `avatarUrl`, `number`, `ovr`, `team`, `goals`, `assists`, `cleanSheets` (`lib/models/player.dart` lines 34–80) |
| `history` | `MatchHistory` records | `id`, `date`, `teams` (nested `Player` lists), `teamNames`, `teamColors`, `playerGoals`, `playerAssists` (`lib/models/match_history.dart`) |
| `stats_archive` | Map per player name (uppercase key) | `goals`, `assists`, `cleanSheets` (`hive_storage.dart` lines 70–84) |
| `metadata` | App metadata | `roster_created_at` ISO timestamp (`hive_storage.dart` lines 8–9, 24–35) |

**Import text:** Held in memory via `importProvider` (`lib/providers/import_provider.dart`) during GENERATE flow; cleared after team generation (`role_selection_screen.dart` line 124). Not a separate persistent box.

**Personal data character:** All stored data is user-entered player names and football/sports statistics. No email, phone, or Apple ID in models.

**`avatarUrl` field:** Defined on `Player` (`player.dart` line 56) but no UI reads or writes it; no `Image.network` usage anywhere in `lib/`.

---

## C. Content that affects age rating

### User-generated content / chat / social

- **No multi-user or social features.** No chat, comments, feeds, or server-synced profiles.
- User-entered text: player names, pasted squad lists, manually entered stats. Stored locally only.
- **Share:** User can share formatted team text to apps of their choice via OS share sheet (`results_screen.dart` lines 249–274). Content is generated locally; sharing is user-initiated.

### Violence, gambling, age-restricted content

- App theme is football/squad management (soccer icons, “GOALS”, “ASSISTS”, “CLEAN SHEETS” labels).
- No gambling, betting, casino, or loot-box mechanics in `lib/`.
- No explicit violence, weapons, or adult content strings found in `lib/` UI text.
- `TeamBalancer` uses `Random` for shuffling players (`team_balancer.dart` line 11) — randomization for team assignment, not gambling.

### Web views / external content loading

- **No** `WebView`, `InAppWebView`, or `url_launcher` in `pubspec.yaml` or `lib/`.
- **No** embedded browser or remote HTML rendering in app code.
- `google_fonts` may fetch font files over HTTPS (see Section B); not user-facing web content.

---

## D. Third-party SDKs and dependencies

From `pubspec.yaml` `dependencies:` and `dev_dependencies:` (lines 31–59).

### Runtime dependencies (`dependencies`)

| Package | Version constraint | Role in this app |
|---------|-------------------|------------------|
| `flutter` | SDK | UI framework |
| `cupertino_icons` | ^1.0.8 | iOS-style icon font |
| `flutter_riverpod` | ^3.3.1 | State management (`ProviderScope`, notifiers, async providers) |
| `google_fonts` | ^8.0.2 | Montserrat font via runtime download / cache |
| `uuid` | ^4.5.3 | Generate unique player IDs locally |
| `flutter_slidable` | ^4.0.3 | Swipe-to-delete on history and stats lists |
| `hive` | ^2.2.3 | Local NoSQL database engine |
| `hive_flutter` | ^1.1.0 | Hive integration with Flutter (init, adapters) |
| `share_plus` | ^12.0.0 | System share sheet for match results text |
| `intl` | ^0.19.0 | Date formatting in match history (`DateFormat`, `match_history_screen.dart` line 86) |

### Dev dependencies (`dev_dependencies`)

| Package | Version constraint | Role |
|---------|-------------------|------|
| `flutter_test` | SDK | Unit/widget tests |
| `flutter_lints` | ^6.0.0 | Lint rules (`analysis_options.yaml`) |
| `flutter_launcher_icons` | ^0.14.3 | Generate app icons (build-time tool) |
| `hive_generator` | ^2.0.1 | Code generation for Hive adapters |
| `build_runner` | ^2.4.13 | Runs code generators |

### Transitive native dependencies

Not fully enumerated in this file. iOS CocoaPods / Android Gradle pull in platform implementations for the packages above (e.g. `path_provider` via `hive_flutter`, `share_plus` platform channels). Inspect `ios/Podfile.lock` and `pubspec.lock` for a complete native transitive tree if Apple asks about specific pod versions.

---

## Appendix: iPad-related code (informational)

These items exist but are **not** iPad-specific branches; reported because v1.0 targets iPhone only (`TARGETED_DEVICE_FAMILY = "1"`).

| Item | Location | Note |
|------|----------|------|
| iPad orientation keys | `ios/Runner/Info.plist` lines 37–43 | `UISupportedInterfaceOrientations~ipad` — unused on iPhone-only distribution |
| Responsive two-column layout | `results_screen.dart` line 72 | `maxWidth < 600` — width-based, not `UIUserInterfaceIdiom` |
| iOS vs Android UI | `lib/utils/platform_ui.dart` | `Platform.isIOS` for Cupertino vs Material — applies to all iOS devices |
| Share without popover origin | `results_screen.dart` line 274 | Relevant on iPad; moot for iPhone-only v1.0 |

No `UIUserInterfaceIdiom`, `isTablet`, or iPad-only layout branches found in `lib/`.
