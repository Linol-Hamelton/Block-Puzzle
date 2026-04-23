/// The lifecycle phases of the game loop.
///
/// Used by the lifecycle state machine (Phase 1 W1) to manage
/// transitions, snapshot persistence, and UI overlays.
enum GameLoopPhase {
  /// App is on the home screen; no game in progress.
  idle,

  /// A game round is actively being played.
  playing,

  /// The game is paused (app backgrounded or user-initiated).
  paused,

  /// The current round has ended; game-over overlay is visible.
  gameOver,
}
