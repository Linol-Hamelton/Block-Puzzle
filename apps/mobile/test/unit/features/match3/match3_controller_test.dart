import 'package:block_puzzle_mobile/core/device/haptics_controller.dart';
import 'package:block_puzzle_mobile/core/logging/app_logger.dart';
import 'package:block_puzzle_mobile/data/analytics/analytics_tracker.dart';
import 'package:block_puzzle_mobile/domain/match3/match3_engine.dart';
import 'package:block_puzzle_mobile/domain/match3/tile.dart';
import 'package:block_puzzle_mobile/features/game_loop/audio/game_sfx_player.dart';
import 'package:block_puzzle_mobile/features/match3/application/match3_controller.dart';
import 'package:block_puzzle_mobile/features/match3/application/match3_session_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _MemoryAnalytics analytics;
  late HapticsController haptics;
  late _NoopSfx sfx;

  setUp(() {
    analytics = _MemoryAnalytics();
    haptics = HapticsController()..isEnabled = false; // no platform calls
    sfx = _NoopSfx();
  });

  Match3Controller makeController({
    int seed = 5,
    Map<String, Object?>? snapshot,
    _FakeStore? store,
  }) {
    return Match3Controller(
      seed: seed,
      sfx: sfx,
      haptics: haptics,
      analyticsTracker: analytics,
      store: store ?? _FakeStore(snapshot: snapshot),
    );
  }

  Map<String, Object?> paramsOf(String event) =>
      analytics.tracked.firstWhere((_Tracked t) => t.name == event).params;

  test('initialize starts a fresh round and emits game_start(match3)', () async {
    final Match3Controller controller = makeController();
    await controller.initialize();

    expect(controller.isGameOver, isFalse);
    expect(controller.score, 0);
    expect(analytics.names, contains('game_start'));
    final Map<String, Object?> p = paramsOf('game_start');
    expect(p['game_id'], 'match3');
    expect(p['mode'], 'match3');
    expect(p['resumed'], false);
  });

  test('a legal swap scores, consumes a move, and tracks line_clear', () async {
    final Match3Controller controller = makeController();
    await controller.initialize();

    final (GridPos, GridPos)? hint = controller.engine.findHint();
    expect(hint, isNotNull);
    final bool ok = controller.trySwap(hint!.$1, hint.$2);

    expect(ok, isTrue);
    expect(controller.score, greaterThan(0));
    expect(controller.movesUsed, 1);
    expect(analytics.names, contains('line_clear'));
    expect(paramsOf('line_clear')['game_id'], 'match3');
  });

  test('resuming a snapshot flags game_start.resumed and keeps the score',
      () async {
    final Match3Engine seeded = Match3Engine(seed: 9)..start();
    final Match3Engine scored = Match3Engine(seed: 9)..restore(seeded.toSnapshot());
    final (GridPos, GridPos)? hint = scored.findHint();
    scored.swap(hint!.$1, hint.$2); // bank some score into the snapshot
    final Map<String, Object?> snapshot = scored.toSnapshot();

    final Match3Controller controller = makeController(snapshot: snapshot);
    await controller.initialize();

    expect(paramsOf('game_start')['resumed'], true);
    expect(controller.score, scored.score);
  });

  test('restart emits a new game_start and resets the run', () async {
    final Match3Controller controller = makeController();
    await controller.initialize();
    final (GridPos, GridPos)? hint = controller.engine.findHint();
    controller.trySwap(hint!.$1, hint.$2);
    expect(controller.movesUsed, 1);

    controller.restart();

    expect(controller.movesUsed, 0);
    expect(controller.score, 0);
    expect(analytics.names.where((String e) => e == 'game_start').length, 2);
  });
}

class _FakeStore extends Match3SessionStore {
  _FakeStore({this.snapshot}) : super(logger: AppLogger());

  Map<String, Object?>? snapshot;

  @override
  Future<int> loadBestScore() async => 0;

  @override
  Future<Map<String, Object?>?> loadSnapshot() async => snapshot;

  @override
  Future<void> saveSnapshot(Map<String, Object?> s) async => snapshot = s;

  @override
  Future<void> clearSnapshot() async => snapshot = null;

  @override
  Future<void> saveBestScore(int s) async {}
}

class _NoopSfx implements GameSfxPlayer {
  @override
  bool isEnabled = true;

  @override
  Future<void> preload() async {}
  @override
  Future<void> onAppResumed() async {}
  @override
  Future<void> playPiecePlaced() async {}
  @override
  Future<void> playInvalidMove() async {}
  @override
  Future<void> playLineClear({required int clearedLines}) async {}
  @override
  Future<void> playCombo({required int comboStreak}) async {}
  @override
  Future<void> playRotate() async {}
  @override
  Future<void> playHold() async {}
  @override
  Future<void> playHardDrop() async {}
  @override
  Future<void> playGameOver() async {}
}

class _MemoryAnalytics implements AnalyticsTracker {
  final List<_Tracked> tracked = <_Tracked>[];

  List<String> get names =>
      tracked.map((_Tracked t) => t.name).toList(growable: false);

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {
    tracked.add(_Tracked(eventName, Map<String, Object?>.from(params)));
  }

  @override
  Future<void> flush({bool force = false}) async {}
  @override
  Future<void> close() async {}
}

class _Tracked {
  const _Tracked(this.name, this.params);
  final String name;
  final Map<String, Object?> params;
}
