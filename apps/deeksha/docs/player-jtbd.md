# Player jobs to be done

## 1. Keep listening when the phone is locked or the app is in the background

When I leave the app while a story is playing, I want playback to continue and Android to show media controls with the episode title, artwork, play/pause, and skip actions.

Acceptance: An Android foreground media service owns the session; the notification and lock-screen controls respond to playback; playback also works when the player route is no longer visible.

## 2. Continue to the next episode

When an episode finishes, I want the next episode in the series to start without returning to the app. A failed progress save must not block playback, and a transient media request failure must have a clear retry path.

Acceptance: The ordered queue is available to the playback service before the end of a track; the next item starts automatically; its title and artwork update in Android controls.

## 3. See what has streamed

When audio is loading or the connection slows, I want to distinguish the played position from the portion already buffered so I can tell whether playback is waiting for data.

Acceptance: The seek bar shows both played and buffered progress; a loading indicator appears while preparing or buffering; seek and playback continue as soon as audio is ready. Buffering is not described as offline unless a network request actually fails.

## Verification

- Widget tests for queue handoff, loading/buffering display, and progress behavior.
- Flutter analysis and the full app test suite.
- Android device check for notification, lock-screen controls, and background transition (requires a physical device or emulator with audio/network access).
