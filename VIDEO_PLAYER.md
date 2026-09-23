# Video Player — MVP Product Requirements

## 1. Product Vision

Build a beautiful, fast, simple, offline-first video player for smartphones.

The app should make local video playback feel effortless:

**Open → find a video → play → enjoy.**

The application is not intended to compete with streaming platforms. Its purpose is to provide an excellent experience for videos already stored on the user's device.

The product should feel like a carefully designed modern mobile application rather than a generic media-player utility.

---

## 2. MVP Goals

The MVP must:

- Discover videos stored on the device.
- Display them in a clean, useful library.
- Start playback quickly.
- Provide excellent playback controls.
- Support fullscreen viewing.
- Remember playback position.
- Make finding videos fast.
- Work reliably without an internet connection.
- Feel smooth on modern and lower-end smartphones.
- Be ready for Google Play Store release.

---

## 3. MVP Features

### 3.1 Local Video Library

Scan and display videos available on the device.

Show useful information such as:

- Thumbnail
- Video title
- Duration
- File size
- Resolution when available
- Date modified when available

The user should be able to browse videos without unnecessary navigation.

Support useful categories such as:

- All Videos
- Recently Added
- Recently Played
- Favorites

Do not create unnecessary categories.

---

### 3.2 Video Discovery

Provide fast search.

Search should work across:

- File name
- Folder name when available

Search results should update quickly while typing.

Provide a clear empty state when nothing matches.

---

### 3.3 Video Playback

The player must support:

- Play / pause
- Seek
- Progress indicator
- Remaining/current time
- Previous / next video where applicable
- Volume
- Mute
- Playback speed
- Fullscreen
- Portrait / landscape orientation
- Restart video
- Resume from previous position

Controls should be easy to reach but should not permanently cover the video.

---

### 3.4 Gesture Controls

Use intuitive gestures where technically appropriate.

Useful gestures may include:

- Horizontal swipe → seek
- Double tap → seek backward/forward
- Vertical gesture → volume or brightness

Gestures must never make basic playback confusing.

Provide visual feedback while a gesture is active.

Do not overload the screen with gesture instructions.

---

### 3.5 Playback Speed

Support common playback speeds:

- 0.5×
- 0.75×
- 1×
- 1.25×
- 1.5×
- 2×

The current speed must always be obvious.

---

### 3.6 Resume Playback

Remember the playback position of videos.

When reopening a partially watched video:

- Continue from the previous position.
- Clearly indicate that playback can be resumed.
- Allow the user to restart from the beginning.

Do not resume videos that were effectively completed.

---

### 3.7 Recently Played

Maintain a local history of recently watched videos.

Show:

- Video
- Last watched time
- Progress when useful

The user must be able to clear history.

---

### 3.8 Favorites

Allow users to favorite videos.

Favorites must be:

- Easy to add/remove.
- Available from the main library.
- Persisted locally.

Provide a useful empty state when there are no favorites.

---

### 3.9 Playlists

Allow users to create simple local playlists.

MVP functionality:

- Create playlist
- Rename playlist
- Delete playlist
- Add video
- Remove video
- Reorder videos
- Play playlist

Do not implement cloud synchronization.

---

### 3.10 Queue

Provide a temporary playback queue.

Users should be able to:

- Add videos to queue.
- View the queue.
- Reorder videos.
- Remove videos.
- Clear the queue.
- Play the next video automatically.

The queue should be temporary and separate from playlists.

---

### 3.11 Sleep Timer

Provide a simple sleep timer.

Allow:

- 15 minutes
- 30 minutes
- 45 minutes
- 60 minutes
- End of current video

The timer should be easy to cancel.

---

### 3.12 Subtitles

If reliable local subtitle support can be implemented without significantly increasing complexity, support common subtitle formats.

At minimum, consider:

- SRT
- VTT

The player should allow the user to:

- Enable/disable subtitles.
- Select an available subtitle track.
- Adjust subtitle appearance only where practical.

Subtitle functionality must not compromise the stability of core playback.

---

### 3.13 Orientation and Fullscreen

The player must provide a polished fullscreen experience.

Requirements:

- Enter fullscreen easily.
- Exit fullscreen easily.
- Support landscape playback.
- Respect device orientation appropriately.
- Hide unnecessary system UI while fullscreen.
- Restore the previous application state when exiting fullscreen.

The transition should feel smooth rather than abrupt.

---

### 3.14 Video Information

Provide an optional information panel for the current video.

Useful information may include:

- File name
- Duration
- File size
- Resolution
- Format/container
- Location/path when appropriate

Do not expose unnecessary technical information to ordinary users.

---

### 3.15 File Handling

Handle unavailable or problematic files gracefully.

Examples:

- File deleted after scanning.
- File moved.
- Unsupported format.
- Corrupted file.
- Permission revoked.
- Playback failure.

Never crash because of an invalid media file.

Show a clear human-readable error and provide an appropriate next action.

---

## 4. Main Screens

The MVP should contain only the screens necessary for the product.

### Home / Library

Purpose:

Give the user immediate access to their videos.

Possible sections:

- Continue Watching
- Recently Added
- Recently Played
- Favorites
- Playlists

Do not turn the home screen into a dashboard full of cards.

---

### Search

Purpose:

Find videos quickly.

Requirements:

- Fast search field.
- Clear button.
- Search results.
- Useful empty state.
- Thumbnail previews.
- Simple result actions.

---

### Player

Purpose:

Provide the best possible video-watching experience.

The video must dominate the screen.

---

### Queue

Purpose:

Manage upcoming playback.

Show:

- Currently playing
- Up next
- Reorder controls
- Remove controls
- Clear queue

---

### Playlists

Purpose:

Manage personal video collections.

Keep the interface simple.

---

### Settings

Only include settings that provide meaningful value.

Possible settings:

- Theme
- Default playback speed
- Resume behavior
- Gesture behavior
- Subtitle preferences
- Library rescan
- Clear history
- Clear cached thumbnails
- About

Do not create a large settings system for the MVP.

---

## 5. Navigation

Use a simple navigation structure.

Recommended primary navigation:

- Home
- Library
- Playlists
- Search

The active player should remain accessible through a persistent Mini Player when appropriate.

The Mini Player should open the full player when tapped.

Do not create unnecessary navigation levels.

---

## 6. Mini Player

When a video is playing outside the full player, display a compact Mini Player.

Show:

- Thumbnail
- Video title
- Play/pause
- Progress
- Tap → open full player

The Mini Player must not permanently consume excessive screen space.

---

## 7. Data and Privacy

The application should be local-first.

User videos should not be uploaded anywhere.

Do not require:

- Account creation
- Cloud storage
- Online synchronization
- Remote media servers
- Analytics that are unnecessary for the MVP

Internet access should not be required for normal video playback.

User data should remain on the device unless a future feature explicitly requires otherwise.

---

## 8. Performance Requirements

The application should:

- Start quickly.
- Scan large libraries efficiently.
- Generate thumbnails efficiently.
- Avoid unnecessary memory usage.
- Avoid loading full-resolution thumbnails when unnecessary.
- Avoid blocking the UI thread.
- Release media resources correctly.
- Handle large video files safely.
- Remain responsive during library operations.

Never load an entire video into memory.

---

## 9. Technical Direction

Use:

- Flutter
- Dart
- Material 3 where appropriate
- A reliable production-ready video playback package
- Local persistence for history, favorites, playlists, and settings
- Proper state management appropriate to the application's size
- Clean separation between UI, application logic, and data access

Do not over-engineer the architecture.

Use the simplest architecture that can remain maintainable as the application grows.

---

## 10. Iconography

Use a consistent modern icon system.

Preferred icon source:

**Hugeicons**

https://hugeicons.com/

Use icons with a consistent visual style.

Do not mix random icon packs.

Do not create custom SVG icons unless a suitable icon genuinely does not exist.

Verify the current Flutter/package availability and license before integration.

---

## 11. Accessibility

The application must support:

- Sufficient contrast
- Text scaling
- Screen readers where practical
- Meaningful semantic labels
- Large enough touch targets
- No information conveyed by color alone
- Clear focus behavior
- RTL layouts

Playback controls must remain usable for people with different accessibility needs.

---

## 12. Error and Empty States

Every important state must have a designed UI.

Include:

- No videos found
- Permission required
- Permission denied
- No search results
- No favorites
- No playlists
- Empty queue
- Unsupported video
- Playback failure
- Missing file
- Library scanning
- Library scan failure

Each state should explain:

1. What happened.
2. What the user can do next.

Avoid technical error messages unless they are useful.

---

## 13. What NOT to Build in MVP

Do not add these unless explicitly requested:

- Video streaming service
- User accounts
- Cloud synchronization
- Social features
- Comments
- Video sharing platform
- AI recommendations
- Online video downloader
- Built-in web browser
- Video editor
- Video converter
- Screen recorder
- Complex equalizer
- Complex audio processing
- DRM systems
- Excessive customization
- Complicated gesture configuration
- Subscription system

The MVP should remain focused.

---

## 14. Definition of Done

The MVP is complete only when:

- The app builds successfully.
- Local videos can be discovered.
- Videos can be played reliably.
- Playback controls work correctly.
- Fullscreen works.
- Orientation handling works.
- Playback position is remembered.
- Favorites work.
- History works.
- Playlists work.
- Queue works.
- Search works.
- Sleep timer works.
- Error states work.
- Permissions are handled correctly.
- The UI matches `UI_DESIGN.md`.
- The app has been tested on a real Android device or representative emulator.
- Release build succeeds.
- No obvious crashes or unfinished screens remain.
- The project is suitable for Google Play Store release.

Do not declare the application finished merely because the code compiles.

The final product should feel like a complete, polished video player rather than an MVP prototype.