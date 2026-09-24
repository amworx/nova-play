# Handoff — Nova Play (local video player)

Handoff written for the next AI assistant continuing work on this project.
Read this fully before touching code. The user is **impatient**: verify APIs, make
decisive single-shot edits, build + install + verify on-device fast, and never
leave the app in a broken intermediate state.

## What the app is

Offline-first local Android video player ("Nova Play"). Scans MediaStore
(photo_manager), plays via `video_player`, remembers favorites / playlists /
resume progress (shared_preferences), full custom player screen with gestures
(seek/brightness/volume/tap/long-press), subtitles, sleep timer, queue, speed
control, share/rename/delete. Light + dark theme, RTL-ready, 1080×2340 target.

## Quick facts

- **Project root**: `C:/Users/HP/Documents/code_repo/video_player`
- **Device**: `RFCWA0BJT9F` (Samsung A346E, Android 16, 1080×2340, density 420,
  px→dp ÷2.625). Also reachable over adb as `10.10.0.6:5555`.
- **Package**: `com.example.video_player`
- **State management**: flutter_riverpod 2.x (not Riverpod 3).
- **Deps** (pubspec): riverpod, video_player 2.14, photo_manager 3.12,
  permission_handler (pinned `12.0.1`), shared_preferences, hugeicons,
  wakelock_plus, screen_brightness, volume_controller, path_provider, share_plus.
- **No git repo** in the project folder. Rollback = manual file snapshots.
  `.rollback_7btn_row/` holds the pre-bottom-bar player state (see below).
- **UI spec**: `UI_DESIGN.md` is authoritative. Premium/minimal, video-focused,
  auto-hide chrome, NOT a VLC/MX/YouTube clone.

## Architecture / key files

```
lib/
  main.dart                      entry (permission flow etc.)
  app.dart                       MaterialApp + Shell (bottom tabs) + themeMode wiring
  models/video_item.dart         VideoItem {id (entityId-or-path), path, entityId, title, ...}
  models/playlist.dart
  data/prefs_store.dart          PrefsStore: favorites/progress/playlists/theme helpers
  data/library_repository.dart   MediaStore scan + cache
  data/subtitle_parser.dart
  state/providers.dart           prefsStoreProvider(plain Provider!), playerProvider,
                                 libraryProvider, favoritesProvider, historyProvider,
                                 playlistsProvider, themeModeProvider
  state/player_controller.dart   PlayerController (ChangeNotifier) — playback, queue,
                                 sleep timer, subtitles, deleteVideo
  ui/screens/player_screen.dart  the big one: player UI + gesture layers + sheets
  ui/screens/home|library|search|playlists|settings_screen.dart
  ui/widgets/...                 mini_player, queue_sheet, video_thumb, video_tile, empty_state
  theme/app_theme.dart           AppTheme.light()/dark()
integration_test/player_controls_test.dart
test/widget_test.dart            3 tests, all pass
```

## Providers — CRITICAL quirks (learned the hard way)

- `prefsStoreProvider` is a **plain `Provider<PrefsStore>`**. Watching it never
  rebuilds when SharedPreferences change. Any UI that must react to prefs writes
  must watch a dedicated StateProvider and the writer must set BOTH the store
  value and the provider state (see `themeModeProvider` + the settings sheet).
- **Do NOT `ref.invalidate(prefsStoreProvider)`** — `playerProvider` watches it,
  invalidating recreates `PlayerController` mid-playback (kills audio).
- `favoritesProvider`/`historyProvider`/`playlistsProvider` are in-memory state
  providers seeded from the store; mutations must update provider + store.
- `libraryProvider` (LibraryNotifier) re-scans MediaStore + re-caches on
  `refresh()`. **Always refresh after add/delete** so dead entries disappear.

## Player screen structure (current)

- Portrait layout = `Column`/`ListView`: `_VideoCard` (with time chip +
  gesture layers) → wave card → `_SpeedRow` → `_ExtraRow`.
- **7-button action bar is a `bottomNavigationBar`, NOT in the list**:
  `_ActionsRow` (Save · Queue · Sleep · Share · Rename · Details · **Delete**)
  wrapped in a `SafeArea` + fixed-height `Container` (**must keep a fixed
  height and `mainAxisSize.min` columns — otherwise the Row's loose full-screen
  constraints stretch every button to fill the screen; this broke the whole UI
  once**). Delete is last, red (`cs.error`), confirmation dialog.
- Fullscreen chrome does NOT use `_ActionsRow`/`_ExtraRow` — it owns separate
  `_fBtn` rows.
- Queue/sleep sheets are **file-level helper functions** (`_queueSheet`,
  `_sleepSheet` in player_screen.dart) so both portrait and any future viewers
  can open them. `_ExtraRow` = subtitles toggle only.

## Delete flow (deleteVideo / deleteVideos)

`PlayerController.deleteVideos(List<VideoItem>)` (single `deleteVideo`
delegates to it):
1. ONE `PhotoManager.editor.deleteWithIds(allIds)` call for all MediaStore
   assets → ONE system trash consent even for bulk deletes, with
   `File(v.path).delete()` fallback for path-only items.
2. Drop deleted ids from the queue; if current was deleted → `next()` (if
   `hasNext`) else `closePlayer()`. **Advance/close FIRST** so
   `closePlayer()`'s progress-write for the deleted item gets overwritten by
   cleanup, not re-added.
3. Persisted cleanup per item: `store.removeFavorite/removeProgress/
   removeFromAllPlaylists`.
4. Shared UI helper `lib/ui/delete_flow.dart → confirmAndDelete()` owns the
   confirm dialog + in-memory refresh (`favoritesProvider` set minus,
   invalidate `history`/`playlists` — playlists invalidate is safe, unlike
   `prefsStoreProvider` which must NEVER be invalidated mid-playback) +
   `libraryProvider.notifier.refresh()` so dead entries vanish everywhere,
   + snackbar. Player + list menus + bulk bar all use it.
5. Lists: `VideoOverflowMenu` has Play/Queue/Favorite/**Delete**;
   long-press any `VideoTile` enters bulk selection
   (`librarySelectionProvider`, tint + check badge, taps toggle);
   Library bar shows count + Favorite-selected + Delete-selected, then
   auto-clears. Pull-to-refresh on All/Recent/Favorites/Folders/FolderDetail;
   Rescan button in Library bar + Settings.

## Verification workflow (text-only — the model can't see screenshots)

1. `flutter analyze` the touched files — must be 0 errors.
2. `flutter test` (test/widget_test.dart, 3 tests).
3. `flutter build apk --debug` then
   `adb -s RFCWA0BJT9F install -r build/app/outputs/flutter-apk/app-debug.apk`.
4. `adb -s RFCWA0BJT9F logcat -c` before launch; launch via
   `adb shell am start -n com.example.video_player/.MainActivity`.
5. `adb shell "uiautomator dump /sdcard/ui.xml; cat /sdcard/ui.xml"` — verify
   bounds + content-desc of every control you touched, screen fills
   (`lowest_node_bottom` ≈ 2340 on device), no overlaps.
6. `adb shell input tap X Y` to drive taps; grep logcat for `FATAL`,
   `Bad state`, `RenderFlex`/overflow (must be 0).

## Known-landmine checklist (do not re-learn)

- **Bottom bar width math**: device width 1080px = 411dp. The 7 buttons fit
  because each `_action` cell is 48dp (40dp circle). Shrinking/label-wrapping
  unbounded columns cause vertical explosions (see fixed-height note above).
  Bar height 84 (was 78) for large-text headroom — keep FIXED either way.
- **Serialized `open()`**: rapid `next()` calls are FIFO-chained in the
  controller; breaking that re-introduces "Bad state: No active player with ID".
  15-tap stress test must stay green.
- **vc-gated UI**: render video surface only when `PlayerStatus.ready`; during
  loading show card spinner + ghost chrome (prevents black screen).
- **Orientation**: fullscreen toggles system rotation + restores prior
  orientation on exit. Gesture layers: double-tap ±10s, long-press 2×, tap
  toggles chrome, drag = seek/brightness/volume (by side).
- **Sleep timer**: `setSleepTimer(Duration)` / `setSleepEndOfVideo` /
  `cancelSleepTimer` exist on the controller; timer fires → closePlayer.
- **Theme switching** was "not working" because of the plain-Provider quirk —
  already fixed via `themeModeProvider`; if it regresses, check the sheet sets
  BOTH store and provider.
- **Permissions**: runtime permission flow lives in `main.dart`; library
  re-init after grant re-scans MediaStore.

## Out-of-scope / not to break

- `lib/mockups/`, `lib/main_mockups.dart` are legacy design-exploration code —
  compile-checked but not part of the app; don't touch unless asked.
- `.rollback_7btn_row/` = snapshot of the 7-button row-in-list state
  (player_screen.dart, player_controller.dart, prefs_store.dart). Restore by
  copying back over `lib/...` if the user asks to reverse the bottom bar.

## Current status

- All user-reported bugs fixed and on-device verified: aspect ratio in
  portrait, "Nothing to play", rapid-next "Bad state", compact one-screen
  portrait layout, 7-button bar (in bottom nav), real delete, theme switcher.
- Analyzer clean (0 errors), tests pass, no FATALs/Bad-state in logcat.
- Known warnings (pre-existing, cosmetic): a couple of `unused_element`
  (e.g. old `_FOLDER`/legacy helpers) — safe to clean or leave.

## Tips for the next session

- Read `UI_DESIGN.md` before any visual change; it drives every layout choice.
- Make ONE consolidated edit per region, then immediately analyze+build+tap-test
  on device; the user reviews by behavior, not by code.
- If you add a pref-backed setting: add a StateProvider + store write + provider
  write in the same edit, wire app-level consumers to the provider.
- Keep debugPrints out of final code unless asked; on-device verification uses
  uiautomator/location logcat — those show enough without print spam.

## Media notification (added 2026-09-24)

- `audio_service 0.18.19` (MIT). `lib/state/media_notification.dart →
  NovaAudioHandler` (same-isolate bridge): transport keys → PlayerController,
  player listener → throttled `mediaItem`/`playbackState` (per-second while
  playing, instant on track/state/control flips; OS projects smooth progress).
- `main.dart` creates ONE PlayerController shared by the handler (builder)
  and UI (`playerProvider.overrideWith`); `AudioService.init` in try/catch —
  if it fails, playback works with no notification. `MainActivity` extends
  `AudioServiceActivity` (shared engine for shade/lock/headset keys).
- Manifest: `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MEDIA_PLAYBACK` +
  `POST_NOTIFICATIONS` (+ service + receiver). POST_NOTIFICATIONS asked
  one-shot on first `open()`; denied = no notification, playback unaffected.
- Dismissal: Close → idle broadcast + `stop()`; `androidResumeOnClick: false`
  so Close REMOVES (not detaches) the notification. Pause keeps a
  dismissible Play notification. Verified live: title/artist/times/Prev/
  Pause/Next, shade-Play resumes, shade-Pause pauses, Close → shade shows
  "No notifications".
- Gotcha (do NOT re-debug): after Close, `dumpsys notification` may still
  list a ghost record while the shade is empty — Samsung NoMan bookkeeping,
  user-invisible. The REAL bug this hunt exposed was an older detached
  leftover (first build used default `androidResumeOnClick: true`); fixed by
  full reinstall. Never trust dumpsys alone — the shade dump is truth.
- Note: shade-Play while backgrounded resumes AUDIO (video surface catches
  up on reopen); headset clicks behave the same. Acceptable media semantics.
- **Up-next strip height is text-scale-driven** (`64 + (11+10)*1.5` via
  `textScalerOf`): a fixed 88px overflowed 11px (RenderFlex, bottom) at
  1.3× text — the "overflow by x pixels" users saw. Never fix a text-height
  box again; same reason the action bar is 84, not 78.

## In-app updates (added 2026-09-23)

- Source: GitHub Releases of `amworx/nova-play`. Check API:
  `releases/latest` → first `.apk` asset (prefers `nova-play-<tag>.apk`).
- New files: `lib/data/update_service.dart` (check + semver compare +
  session-only `UpdateState`), `test/update_check_test.dart`,
  `android/app/src/main/res/xml/filepaths.xml`,
  `.github/workflows/release.yml` (tag `v*` → analyze+test → release APK
  with `--build-name=<tag>` `--build-number=<run>` so versionCode always rises).
- Deps added: `ota_update 7.1.0` (MIT, download + auto install-intent),
  `package_info_plus` (was transitive, now direct).
- Android: `INTERNET` + `REQUEST_INSTALL_PACKAGES` + `OtaUpdateFileProvider`
  (`${applicationId}.ota_update_provider`); desugaring on in
  `android/app/build.gradle.kts` (`desugar_jdk_libs:2.0.4`).
- UI: Settings → "Updates" group (`_UpdatesSection` in settings_screen.dart),
  ephemeral `updateStateProvider` (no prefs keys). Pre-flight
  `Permission.requestInstallPackages` check with "Open app settings" recovery;
  CANCELED/ALREADY_RUNNING/DOWNLOAD_ERROR all mapped to human messages.
- Landmines: default `execute()` (NOT `usePackageInstaller:true`) is what
  auto-opens the installer — don't "upgrade" it. Debug-key signing for now;
  Play builds must REMOVE `REQUEST_INSTALL_PACKAGES` and use Play In-App
  Updates instead. About row now shows the real installed version.
## App icon (v2 - user-picked loops mark, 2026-09-24)

- Teal tile #3ADBB4 + navy #0E0E38 interlocking-loops ribbon (user Image 1, redrawn as an original PIL drawing - never copy web pixels).
- Legacy: full-bleed rounded PNGs per density. Adaptive: teal ic_launcher_background color + transparent drawable/ic_launcher_foreground.png (loops inside the 72dp safe zone).
- Generator lives in temp dir (nova_icon_v2.py), not in repo. Verify via APK zip-listing + pixel sampling + ASCII composition preview (text-only model cannot see screenshots - preview that way before every icon change).

## App icon (v3 - pixel-faithful, 2026-09-24)

- Source: icon_images/img.png (user-supplied, 1000px, teal #45D6AC + navy mark, bbox ~224,270-774,728). v2 procedural redraw was rejected - never redraw blind again.
- Conversion: mark pixels extracted with teal-distance alpha feathering into drawable/ic_launcher_foreground.png (62% safe-zone span); legacy PNGs are straight resizes; bg color sampled exact. Generator: nova_icon_v3.py in temp dir.
