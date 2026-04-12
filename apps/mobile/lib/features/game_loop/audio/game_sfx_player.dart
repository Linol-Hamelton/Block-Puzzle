abstract interface class GameSfxPlayer {
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
