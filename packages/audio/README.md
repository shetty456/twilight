# Twilight audio

Reusable background playback for apps with ordered audio items. The host app supplies metadata and a URL resolver; this package owns the player, Android/iOS media session, queue handoff, and buffered-position state.

Call `BackgroundAudioQueue.initialize` before `runApp`, create one `BackgroundAudioQueue` for the app lifetime, and call `load` with an ordered list of `AudioQueueItem`s. The host Android manifest and iOS Info.plist must include the media service declarations described in the package setup. A URL resolver can return short-lived signed URLs; the next item is resolved ahead of playback and retried after a transient failure.
