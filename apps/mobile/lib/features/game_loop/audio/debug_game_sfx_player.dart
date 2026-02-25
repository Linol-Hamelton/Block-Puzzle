import '../../../core/logging/app_logger.dart';
import 'game_sfx_player.dart';

class DebugGameSfxPlayer implements GameSfxPlayer {
  DebugGameSfxPlayer({
    required AppLogger logger,
  }) : _logger = logger;

  final AppLogger _logger;

  @override
  Future<void> preload() async {
    _logger.info('SFX hook: preload');
  }

  @override
  Future<void> playPiecePlaced() async {
    _logger.info('SFX hook: piece_placed');
  }

  @override
  Future<void> playInvalidMove() async {
    _logger.info('SFX hook: invalid_move');
  }

  @override
  Future<void> playLineClear({
    required int clearedLines,
  }) async {
    _logger.info('SFX hook: line_clear ($clearedLines)');
  }

  @override
  Future<void> playCombo({
    required int comboStreak,
  }) async {
    _logger.info('SFX hook: combo x$comboStreak');
  }

  @override
  Future<void> playGameOver() async {
    _logger.info('SFX hook: game_over');
  }
}
