# Nova Play

Beautiful, fast, offline-first local video player for Android smartphones.

Open → find a video → play → enjoy. No accounts, no cloud, no streaming — your videos stay on your device.

## Features

- **Local library** — scans on-device videos via MediaStore (`photo_manager`), with thumbnails, duration, and cache
- **Playback** — play/pause, seek, progress + remaining time, previous/next, restart, resume from last position
- **Full player** — custom player screen with auto-hide chrome, fullscreen + orientation handling, wakelock
- **Gestures** — double-tap ±10s, long-press 2×, tap toggles chrome, drag to seek / brightness (left) / volume (right)
- **Speed** — 0.5× / 0.75× / 1× / 1.25× / 1.5× / 2×
- **Queue** — now playing + up next, reorder / remove / clear, auto-advance
- **Playlists & favorites** — create / rename / delete, add / remove / reorder, persisted locally
- **History & resume** — recently played, continue watching with progress
- **Sleep timer** — 15 / 30 / 45 / 60 min + end-of-video, easy cancel
- **Subtitles** — SRT / VTT, enable/disable + track selection
- **File actions** — share, rename, details, real delete (MediaStore trash + provider + cache cleanup)
- **Search** — instant file/folder name search with empty state
- **Themes** — light + dark (video-comfortable dark), system / light / dark setting
- **RTL-ready**, Hugeicons throughout, 48dp touch targets

## Screens

Home (Continue Watching / Recently Added / Favorites) · Library · Playlists · Search · Player · Mini Player · Settings

Spec: [`UI_DESIGN.md`](UI_DESIGN.md) is authoritative for all visual decisions.
Requirements: [`VIDEO_PLAYER.md`](VIDEO_PLAYER.md). Continuation notes: [`handoff.md`](handoff.md).

## Stack

Flutter (Material 3) · `flutter_riverpod` 2.x · `video_player` 2.14 · `photo_manager` 3.12 · `permission_handler` 12.0.1 · `shared_preferences` · `hugeicons` · `wakelock_plus` · `screen_brightness` · `volume_controller` · `path_provider` · `share_plus`

## Getting started

Prerequisites: Flutter SDK (Dart ^3.12.2), Android SDK, a device or emulator.

```bash
flutter pub get
flutter run
```

Tests and analysis:

```bash
flutter analyze
flutter test
```

Debug APK + install (device `RFCWA0BJT9F`):

```bash
flutter build apk --debug
adb -s RFCWA0BJT9F install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s RFCWA0BJT9F shell am start -n com.example.video_player/.MainActivity
```

## Project structure

```
lib/
  main.dart                    entry (orientation lock, prefs override, zoned errors)
  app.dart                     MaterialApp + Shell (bottom tabs) + theme wiring
  models/video_item.dart       VideoItem {id, path, entityId, title, ...}
  models/playlist.dart
  data/prefs_store.dart        favorites / progress / playlists / theme persistence
  data/library_repository.dart MediaStore scan + cache
  data/subtitle_parser.dart    SRT / VTT
  state/providers.dart         prefsStore, player, library, favorites, history, playlists, themeMode
  state/player_controller.dart playback, queue, sleep timer, subtitles, deleteVideo
  ui/screens/player_screen.dart  player UI + gestures + sheets (the big one)
  ui/screens/home|library|search|playlists|settings_screen.dart
  ui/widgets/                  mini_player, queue_sheet, video_thumb, video_tile, empty_state
  theme/app_theme.dart         light() / dark()
test/widget_test.dart
integration_test/player_controls_test.dart
```

## Contributor notes

- `prefsStoreProvider` is a plain `Provider` — it never rebuilds on writes. Pref-backed UI must watch a dedicated `StateProvider` and writers must set **both** store + provider (see `themeModeProvider`).
- Never `ref.invalidate(prefsStoreProvider)` — `playerProvider` watches it and would recreate `PlayerController` mid-playback.
- `favorites` / `history` / `playlists` are in-memory providers seeded from the store; mutate provider **and** store together.
- Always `libraryProvider.notifier.refresh()` after add/delete so dead entries disappear.
- Player `open()` calls are serialized (FIFO) — keep that; breaking it re-introduces "Bad state: No active player".
- Portrait player action bar lives in `bottomNavigationBar` with fixed height + `mainAxisSize.min` columns; fullscreen chrome owns separate button rows.
- `lib/mockups/` + `lib/main_mockups.dart` are legacy design explorations — compile-checked, not part of the app.

## Status

MVP complete on-device: aspect ratio, resume, rapid-next, one-screen portrait layout, 7-button bar, real delete, theme switcher. `flutter analyze` clean, widget tests pass, no FATALs in logcat.
