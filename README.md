# Threadcast

**Convert Reddit posts into multi-speaker AI podcasts — entirely on-device.**

Threadcast takes Reddit posts from story-driven subreddits like r/AITAH and r/relationship_advice, scrapes the post and top comments, generates a faithful podcast-style transcript using an on-device LLM, and synthesises multi-speaker audio using an on-device TTS engine. No cloud APIs. No subscription. No per-episode cost.

---

## How it works

```
Reddit URL(s)
     │
     ▼
RedditScraper (dio, public JSON or OAuth)
     │ post + comments
     ▼
LlmPromptBuilder
     │ two-phase prompts
     ▼
On-device LLM  ──── Phase 1: tone + speaker analysis
     │          ──── Phase 2: full transcript JSON
     ▼
VoiceAssignment (Kokoro voice pool)
     │ speaker → voice map
     ▼
TtsService (Sherpa-ONNX + Kokoro-82M)
     │ per-segment WAV files
     ▼
AudioStitcher (ffmpeg_kit_flutter_new)
     │ single episode WAV
     ▼
Player / Library / Export (MP3 + share sheet)
```

---

## Tech stack

| Layer | Library / Framework | Notes |
|---|---|---|
| UI + shared logic | Flutter (Dart) | iOS + Android from one codebase |
| State management | Riverpod | `StateNotifierProvider` throughout |
| Navigation | go_router | Deep link support for OAuth callback |
| Android LLM | ML Kit GenAI Prompt API | `com.google.mlkit:genai-prompt:1.0.0-beta1` — Gemini Nano via AICore |
| iOS LLM | Foundation Models | `LanguageModelSession` — iOS 26+ only |
| LLM bridge | Flutter MethodChannel | `com.threadcast.app/llm` |
| TTS engine | Sherpa-ONNX + Kokoro-82M | 82M parameter model, ~330 MB, runs on-device |
| Audio playback | just_audio | Position stream for transcript sync |
| Audio stitching | ffmpeg_kit_flutter_new | Replaces retired ffmpeg_kit_flutter (Jan 2025) |
| Database | Drift + drift_flutter | SQLite ORM, replaces unmaintained Isar |
| HTTP client | dio | Reddit API requests |
| OAuth | flutter_web_auth_2 | PKCE flow, deep link callback |
| Secure storage | flutter_secure_storage | OAuth tokens |
| Sharing | share_plus | MP3 export to OS share sheet |

### Minimum OS requirements

| Platform | Minimum | Reason |
|---|---|---|
| Android | **API 36 (Android 16)** | Required for guaranteed AICore / Gemini Nano availability |
| iOS | **iOS 26** | Required for Foundation Models framework |

Devices below these versions see an informational "coming soon" screen. Phase 2 will add a private model fallback for older devices.

---

## Prerequisites

- **Windows 10 21H1+** (build 19041+), run as Administrator
- **winget** — comes with Windows 11; install "App Installer" from the Microsoft Store on Windows 10
- 30 GB free disk space (Android SDK + emulator images + Kokoro TTS model)
- Internet connectivity

The setup script handles everything else automatically.

---

## Quickstart (fresh machine)

```powershell
# 1. Clone the repo
git clone https://github.com/your-org/Threadcast D:\github\Threadcast
cd D:\github\Threadcast

# 2. Run setup (as Administrator)
.\setup-threadcast-env.ps1

# 3. Open a new terminal (PATH changes require a fresh shell), then:
flutter doctor          # fix any [!] items
flutter run             # first run fails on ffmpeg AAR download -- run TWICE
flutter run             # second run succeeds
```

That's it. The setup script installs JDK 17, Android Studio, the Android SDK (API 35 + 36), a Pixel 8 Pro AVD, Flutter, Node.js, Claude Code, and the Kokoro TTS model files. It then scaffolds the project, runs `flutter pub get`, and generates the Drift database code.

### Migrating an existing project (Isar → Drift)

If you have an existing project that still uses Isar or the retired `ffmpeg_kit_flutter`:

```powershell
.\migrate-dependencies.ps1
flutter analyze          # expect 0 errors
flutter run              # run TWICE
```

---

## Project structure

```
lib/
├── app.dart                       # GoRouter + ProviderScope
├── core/
│   ├── constants.dart             # Reddit client ID, user agent, redirect URI
│   ├── errors.dart                # Typed error codes
│   ├── extensions.dart            # File.deleteIfExists()
│   └── providers.dart             # All top-level Riverpod providers
├── features/
│   ├── create/                    # URL input + generation pipeline
│   ├── library/                   # Saved episodes list
│   ├── onboarding/                # Reddit OAuth flow
│   └── player/                    # Audio playback + transcript view
├── models/
│   └── episode.dart               # Drift table schema + AppDatabase
└── services/
    ├── llm/                       # LLM abstraction + prompt builder
    │   ├── llm_service.dart       # Abstract interface
    │   ├── os_llm_service.dart    # MethodChannel impl (mock in dev)
    │   └── llm_prompt_builder.dart
    ├── reddit/                    # Scraper + OAuth
    └── tts/                       # Sherpa-ONNX wrapper + audio stitcher

android/app/src/main/kotlin/com/threadcast/app/
├── MainActivity.kt
└── llm/
    ├── LlmPlugin.kt               # MethodChannel handler
    └── GeminiNanoService.kt       # Gemini Nano integration (stub → implement in #5)

ios/Runner/
├── AppDelegate.swift
└── llm/
    ├── LlmPlugin.swift            # MethodChannel handler
    └── FoundationModelService.swift  # Foundation Models (stub → implement in #6)
```

---

## Database (Drift)

Drift generates an immutable `Episode` data class. **Never use cascade mutation.** All writes go through `EpisodesCompanion` with `Value()` wrappers.

```dart
// Write (insert or upsert)
await db.upsertEpisode(EpisodesCompanion(
  episodeId:       Value(episodeId),
  title:           Value('Episode title'),
  subreddit:       Value('AITAH'),
  sourceUrlsJson:  Value(AppDatabase.encodeUrls(urls)),
  tone:            Value('talk_show'),
  createdAt:       Value(DateTime.now()),
  durationSeconds: Value(600),
  audioWavPath:    Value(path),
  status:          Value(AppDatabase.encodeStatus(EpisodeStatus.complete)),
));

// Partial update (e.g. after MP3 encoding)
await db.updateEpisodeFields(episode.id, audioMp3Path: mp3Path);

// Read
final episode  = await db.episodeById(uuid);        // Future<Episode?>
final episodes = await db.completedEpisodes();       // newest first

// Delete
await db.deleteEpisodeById(episode.id);

// URL helpers
AppDatabase.encodeUrls(urls)                   // List<String> → JSON string
AppDatabase.decodeUrls(episode.sourceUrlsJson) // JSON string → List<String>
```

If you change the schema in `episode.dart`, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Helpful commands

```bash
# Analyze — should always be 0 errors
flutter analyze

# Run on a connected device or emulator
flutter run

# Run on a specific device
flutter devices                         # list available
flutter run -d emulator-5554

# Start the Pixel 8 Pro AVD
C:\Users\<you>\AppData\Local\Android\Sdk\emulator\emulator.exe -avd Pixel_8_Pro_API_36

# Rebuild Drift generated code
dart run build_runner build --delete-conflicting-outputs

# Check outdated packages
flutter pub outdated

# Run tests
flutter test

# Build release APK
flutter build apk --release

# Format all Dart files
dart format .
```

---

## Reddit API

### Development (no credentials needed)

`AppConstants.redditClientId` is empty by default, which activates the public `.json` endpoint:

```
GET https://www.reddit.com/r/AITAH/comments/{id}.json?sort=top&limit=100&depth=3&raw_json=1
```

10 requests per minute per IP. Fully sufficient for development — a single post fetch is 1–2 requests.

### Production (OAuth)

Apply for credentials at [support.reddithelp.com](https://support.reddithelp.com/hc/en-us/requests/new) (category: Developer Support). Once approved, register the app at `reddit.com/prefs/apps`, set the redirect URI to `threadcast://oauth/callback`, and paste the client ID into `AppConstants.redditClientId`.

Before going to production, update the user agent in `AppConstants.redditUserAgent` — replace `YOUR_REDDIT_USERNAME` with your actual Reddit account (see issue #23).

---

## iOS builds

iOS builds require macOS + Xcode. Since this project is developed on Windows, use **Codemagic CI** for iOS builds (see issue #27). Codemagic offers 500 free build minutes per month.

Before your first iOS build, you need to:
1. Change the bundle identifier from `com.threadcast.threadcast` to `com.threadcast.app` in Xcode (Signing & Capabilities — see issue #18)
2. Enable the **Foundation Models** entitlement (Signing & Capabilities → + Capability → Foundation Models)

---

## Known issues

| # | Issue | Status |
|---|---|---|
| #16 | LlmPlugin not registered in `MainActivity.kt` / `AppDelegate.swift` | Open — implement with #5 and #6 |
| #17 | minSdk = 36 | **Closed** — already done |
| #18 | Bundle ID mismatch (`com.threadcast.threadcast` vs `com.threadcast.app`) in Xcode | Open — manual Xcode step (requires macOS) |
| #19 | `UnsupportedDeviceScreen` uses a full `Scaffold` (causes nested Scaffold error) | Open — fix before using inline |

There is also a known quirk with `ffmpeg_kit_flutter_new`: the **first** `flutter run` or `flutter build` will fail with an AAR download error. Run the same command a **second time** and it will succeed. This is expected, documented behavior.

---

## GitHub issues

All development work is tracked in [threadcast-github-issues.md](threadcast-github-issues.md).

**Phase 1 priority order (recommended):**

Start with pure Dart issues that run on the emulator and have no native dependencies:

1. **#1** — RedditPost / RedditComment JSON parsing
2. **#2** — RedditScraper HTTP + URL extraction
3. **#4** — LlmPromptBuilder (mostly done — review and close)
4. **#3** — Create screen UI

Then native LLM (requires physical device):

5. **#5** — Android LLM platform channel (includes #16 fix)
6. **#6** — iOS LLM platform channel (includes #16 fix for iOS)

Then audio pipeline:

7. **#7** — espeak-ng-data first-run extraction
8. **#8** — TtsService (Sherpa-ONNX)
9. **#9** — AudioStitcher (mostly done — review and close)

Then UI polish and infrastructure:

10. **#10, #11, #12** — Player, transcript view, library
11. **#13** — MP3 export + share sheet
12. **#15** — Reddit OAuth 2.0

---

## Troubleshooting

**`flutter run` fails with Drift `isolateDebugLog` error:**

```bash
flutter pub upgrade drift drift_dev drift_flutter
flutter pub get
flutter run
```

If the issue persists, delete `pubspec.lock` and regenerate:

```bash
rm pubspec.lock
flutter pub get
flutter run
```

**`ffmpeg_kit_flutter_new` AAR download fails on first build:**

Expected. Run `flutter run` a second time.

**Riverpod `analyzer` version warning during build_runner:**

Safe to ignore. The warning `Your current analyzer version may not fully support your current SDK version` is cosmetic — the build succeeds and `episode.g.dart` is generated correctly.

**Drift `Could not format generated source` warning:**

Safe to ignore. Cosmetic only — `episode.g.dart` is generated correctly despite this warning.

**`drift_dev` "Could not format generated source":**

Cosmetic only. The generated `episode.g.dart` is valid — this warning is a known issue in `drift_dev` 2.x and does not affect functionality.
