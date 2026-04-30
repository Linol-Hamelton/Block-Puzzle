abstract interface class GameSfxPlayer {
  bool get isEnabled;
  set isEnabled(bool value);

  Future<void> preload();

  Future<void> onAppResumed();

  Future<void> playPiecePlaced();

  Future<void> playInvalidMove();

  Future<void> playLineClear({
    required int clearedLines,
  });

  Future<void> playCombo({
    required int comboStreak,
  });

  Future<void> playGameOver();
}
