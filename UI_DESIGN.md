# Video Player — UI Design & UX Specification

## 1. Design Goal

Create a video player that feels:

- Modern
- Premium
- Minimal
- Calm
- Fast
- Intuitive
- Distinctive

The design should make video playback the hero.

The application should feel carefully designed rather than like a collection of standard Flutter widgets.

---

## 2. Core Design Principle

The interface should disappear when the user watches a video.

The hierarchy is:

**Video → Playback controls → Navigation → Secondary information**

The video must always receive the strongest visual priority.

Do not allow secondary UI elements to visually compete with the video.

---

## 3. Visual Identity

Create a distinctive visual language using:

- Strong typography
- Generous spacing
- Clean surfaces
- Controlled corner radius
- Subtle depth
- Restrained use of color
- Smooth transitions
- Consistent iconography

Use one primary accent color throughout the application.

Allow the current video artwork/thumbnail to influence accent colors only where it improves the experience.

Do not use colorful gradients everywhere.

Do not make every component a card.

Do not make every element rounded.

---

## 4. Theme

Support:

- Dark theme
- Light theme

Dark mode should feel especially comfortable for video watching.

Use true visual hierarchy rather than simply changing every surface to black.

Suggested dark hierarchy:

- Background: very dark neutral
- Primary surface: slightly lighter
- Secondary surface: subtle elevation
- Primary text: strong contrast
- Secondary text: reduced contrast
- Accent: reserved for important actions

The exact colors should be selected by the AI based on the overall design rather than copied from another application.

---

## 5. Typography

Typography should be one of the main elements of the visual identity.

Use:

- Strong page titles
- Clear section headings
- Comfortable body text
- Smaller secondary metadata

Avoid excessive font sizes.

Avoid using bold text everywhere.

Use typography to establish hierarchy instead of adding more containers.

Video titles should remain readable even when long.

Handle long titles gracefully with:

- Ellipsis
- Multiple lines where appropriate
- Proper spacing

---

## 6. Iconography

Use a single consistent icon family.

Preferred icon library:

**Hugeicons**

https://hugeicons.com/

Use modern icons with consistent stroke/weight characteristics.

Icons should:

- Have clear meaning.
- Have sufficient visual size.
- Have appropriate touch areas.
- Use consistent style throughout the application.

Do not mix unrelated icon libraries.

Do not use emojis as UI icons.

Do not create custom icons when a suitable Hugeicons icon exists.

---

## 7. Spacing

Use a consistent spacing system.

Prefer predictable spacing based on a small set of values rather than arbitrary numbers.

Maintain:

- Comfortable screen margins.
- Clear separation between sections.
- Adequate spacing around interactive controls.
- More whitespace around important content.

Avoid cramped interfaces.

Avoid excessive empty space that makes the application feel unfinished.

---

## 8. Touch Targets

Interactive controls should be comfortable to use on a smartphone.

Target at least approximately:

**48 × 48 dp**

for important touch targets.

The visible icon can be smaller than the touch area.

Never make important playback controls tiny simply to save space.

---

# 9. Home Screen

The home screen should immediately answer:

**"What can I watch?"**

Recommended structure:

### Header

Include:

- App identity
- Search
- Settings

Keep the header clean.

Do not create a large dashboard header.

### Continue Watching

If the user has partially watched videos, show a prominent but simple Continue Watching section.

Each item can show:

- Thumbnail
- Title
- Progress
- Remaining time

The progress indicator should be subtle.

### Recently Added

Show recently discovered videos.

### Recently Played

Show recently watched videos when useful.

### Favorites

Show a compact entry point rather than a huge section.

### Playlists

Show user-created playlists when they exist.

Do not show empty sections simply because the feature exists.

---

# 10. Library Screen

The library should prioritize browsing.

Possible filtering/navigation:

- All
- Recent
- Favorites
- Folders

Use tabs or compact filters only when they genuinely improve navigation.

Video items should generally contain:

- Thumbnail
- Title
- Duration
- Optional metadata
- Overflow menu

The thumbnail should be visually dominant.

Do not put every metadata field on the main row.

---

# 11. Video Cards / Rows

Use the appropriate layout for the context.

### Compact List

Useful for:

- Large libraries
- Search results
- Queue

Show:

- Thumbnail
- Title
- Short metadata
- Duration
- Overflow menu

### Larger Grid

Useful when visual browsing is more important.

Show:

- Large thumbnail
- Title
- Duration

Do not create excessive information density.

The user should be able to identify a video primarily from its thumbnail and title.

---

# 12. Search

Search should feel instant.

The search screen should contain:

- Search field
- Clear button
- Results
- Optional recent searches

While typing:

- Update results quickly.
- Avoid unnecessary loading indicators.
- Keep keyboard interaction smooth.

When there are no results, explain that clearly.

Do not show an empty blank screen.

---

# 13. Mini Player

When playback continues outside the full player, show a compact Mini Player above the primary navigation when appropriate.

It should contain:

- Thumbnail
- Title
- Play/pause
- Progress

Tap anywhere meaningful on the Mini Player to open the full player.

Keep it compact.

Do not turn the Mini Player into another full control panel.

---

# 14. Full Video Player

This is the most important screen in the application.

The video should occupy almost the entire available screen.

Controls should be layered over the video when visible.

### Top Area

Possible controls:

- Back
- Video title when useful
- More/options

Keep this area minimal.

### Center

Primary playback interaction:

- Play/pause
- Optional seek feedback

The play/pause button should be visually clear without becoming oversized.

### Bottom Area

Include:

- Current time
- Progress bar
- Remaining time
- Fullscreen
- Relevant playback controls

Secondary controls can appear in a bottom control area or overflow menu.

Do not display every possible feature simultaneously.

---

# 15. Player Controls Behavior

Controls should automatically hide after a short period of inactivity.

Tapping the video should:

- Show controls when hidden.
- Optionally pause/play only if that behavior is explicitly chosen and clearly communicated.

Do not create accidental playback changes.

Controls should animate smoothly when appearing/disappearing.

Animations should be fast and subtle.

---

# 16. Gesture UX

Gestures should feel natural.

Potential interactions:

### Horizontal

Swipe horizontally to seek.

Display temporary feedback such as:

- Seek direction
- Amount skipped
- Updated timestamp

### Double Tap

Double tap left/right side for backward/forward seeking.

Provide clear visual feedback.

### Vertical

If brightness/volume gestures are implemented:

- Left side → brightness
- Right side → volume

Display temporary feedback.

Gestures must not interfere with normal scrolling or controls.

---

# 17. Fullscreen

Fullscreen should feel immersive.

When entering fullscreen:

- Hide unnecessary UI.
- Expand video to available space.
- Adapt controls to landscape where appropriate.
- Respect safe areas.

When exiting:

- Restore the previous navigation context.
- Preserve playback state.

Do not create a visually jarring transition.

---

# 18. Queue

The queue should be simple and functional.

Structure:

### Now Playing

Clearly identify the current video.

### Up Next

Show upcoming videos.

Users should be able to:

- Reorder
- Remove
- Clear

Use drag handles only where necessary.

Do not add excessive queue controls.

---

# 19. Playlists

Playlist screen should feel like a simple personal collection.

Provide:

- Create
- Rename
- Delete
- Add videos
- Remove videos
- Reorder
- Play

Use clean list layouts.

Do not turn playlists into complex management dashboards.

---

# 20. Bottom Navigation

Use bottom navigation only for major destinations.

Recommended:

- Home
- Library
- Playlists
- Search

Do not add a bottom-navigation item for every feature.

Settings should normally remain accessible from the header or another secondary location.

---

# 21. Settings

Settings should be organized into small logical groups.

Possible groups:

### Playback

- Default playback speed
- Resume behavior
- Gesture settings

### Subtitles

- Default subtitle behavior
- Appearance preferences

### Library

- Rescan
- History
- Thumbnail cache

### Appearance

- Theme

### About

- App version
- Licenses
- About the application

Avoid long lists of obscure options.

---

# 22. Empty States

Empty states are part of the design, not an afterthought.

Examples:

### No Videos

Explain that the application could not find local videos.

Provide the relevant action.

### No Favorites

Explain how to add favorites.

### No Playlists

Provide a clear create-playlist action.

### No Search Results

Clearly explain that nothing matched the search.

### Empty Queue

Provide a simple explanation and a path back to browsing.

Empty states should use:

- Simple icon/illustration
- Short title
- Short explanation
- One clear action where appropriate

Do not fill empty states with unnecessary artwork or text.

---

# 23. Loading States

Avoid large blocking spinners whenever possible.

Prefer:

- Skeleton content
- Subtle progress
- Incremental loading

The interface should remain responsive while videos are being scanned.

Do not freeze the entire screen during library operations.

---

# 24. Error States

Errors should be understandable.

Instead of exposing technical messages, use language that explains:

**What happened → What can I do?**

Examples:

- "This video couldn't be played."
- "The file is no longer available."
- "We couldn't access your videos."
- "Try again."

Provide Retry or relevant recovery actions.

---

# 25. Motion

Motion should communicate state changes.

Use subtle animations for:

- Mini Player appearance
- Mini Player dismissal
- Controls appearing/disappearing
- Play/pause changes
- Favorite changes
- Queue changes
- Navigation transitions
- Fullscreen transitions
- Thumbnail loading

Avoid:

- Long animations
- Decorative animation everywhere
- Bouncing UI
- Excessive scaling
- Distracting transitions

The application should feel fast.

---

# 26. Accessibility

Design for accessibility from the beginning.

Ensure:

- Touch targets are sufficiently large.
- Icons have semantic labels.
- Text has adequate contrast.
- Text scaling works.
- Information is not communicated through color alone.
- Important actions remain understandable without icons alone.
- Screen readers can identify important controls.
- RTL layouts work correctly.

---

# 27. RTL Support

The application must be RTL-ready.

Do not hardcode left/right positioning.

Use Flutter's directional layout concepts.

Icons that communicate direction must also adapt appropriately when required.

Do not assume English is the only language.

---

# 28. Responsive Design

The design must work on:

- Small phones
- Large phones
- Portrait
- Landscape

Do not simply scale everything proportionally.

Adapt layouts intelligently.

For example:

- Reduce secondary information on small screens.
- Use wider layouts when space permits.
- Give the video maximum useful space in landscape.

---

# 29. Interaction Principles

Every screen should answer:

1. Where am I?
2. What can I do here?
3. What is the primary action?
4. How do I go back?

Avoid hidden functionality unless the interaction is familiar.

Important actions should never require unnecessary navigation.

---

# 30. Visual Restraint

Do not try to make the application look premium by adding more visual elements.

Premium should come from:

- Spacing
- Typography
- Consistency
- Motion
- Alignment
- High-quality thumbnails
- Clear hierarchy
- Excellent interaction details

Less should often be more.

---

# 31. Originality

Do not copy the visual design of:

- VLC
- MX Player
- YouTube
- Netflix
- Apple TV
- Google Photos
- Spotify
- Any other existing media application

Study common UX patterns only when necessary.

The final interface should have its own visual identity.

---

# 32. UI Implementation Rule

Before implementing a screen:

1. Understand the purpose of the screen.
2. Identify the primary user action.
3. Apply this design specification.
4. Keep secondary actions visually subordinate.
5. Consider small-screen usability.
6. Consider light/dark themes.
7. Consider RTL.
8. Consider accessibility.
9. Implement the simplest interface that satisfies the requirement.

Do not invent additional UI elements simply because there is empty space.

---

# 33. Final Visual Quality Check

Before declaring the application complete, inspect every major screen visually.

Check:

- Alignment
- Spacing
- Typography
- Icon consistency
- Contrast
- Touch targets
- Thumbnail quality
- Navigation
- Animation
- Dark theme
- Light theme
- RTL
- Landscape
- Small-screen behavior
- Empty states
- Error states
- Loading states

Fix visual problems rather than accepting them as "good enough."

The final result should look and feel like a deliberately designed modern mobile product, not a Flutter prototype.