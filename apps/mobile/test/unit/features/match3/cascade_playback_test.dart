import 'package:block_puzzle_mobile/domain/match3/cascade_resolver.dart';
import 'package:block_puzzle_mobile/domain/match3/match3_engine.dart';
import 'package:block_puzzle_mobile/domain/match3/special_combo.dart';
import 'package:block_puzzle_mobile/domain/match3/tile.dart';
import 'package:block_puzzle_mobile/domain/match3/tile_grid.dart';
import 'package:block_puzzle_mobile/features/match3/application/cascade_playback.dart';
import 'package:flutter_test/flutter_test.dart';

const TileColor r = TileColor.ruby;
const TileColor m = TileColor.amber;
const TileColor c = TileColor.citrine;
const TileColor e = TileColor.emerald;

TileGrid boardOf(List<List<TileColor>> rows) => TileGrid.ofColors(
      width: rows.first.length,
      height: rows.length,
      colors: <TileColor?>[for (final List<TileColor> row in rows) ...row],
    );

CascadeStep stepWith({
  required Set<GridPos> cleared,
  required TileGrid boardAfter,
  int level = 1,
  Map<GridPos, TileColor> colors = const <GridPos, TileColor>{},
}) =>
    CascadeStep(
      cleared: cleared,
      clearedColors: colors,
      cascadeLevel: level,
      longestRun: 3,
      gained: 90,
      boardAfter: boardAfter,
    );

void main() {
  const CascadePlayback playback = CascadePlayback();

  final TileGrid a = boardOf(<List<TileColor>>[
    <TileColor>[r, r, r],
    <TileColor>[m, c, e],
    <TileColor>[c, e, m],
  ]);
  final TileGrid b = boardOf(<List<TileColor>>[
    <TileColor>[m, c, e],
    <TileColor>[c, e, m],
    <TileColor>[e, m, c],
  ]);
  final TileGrid d = boardOf(<List<TileColor>>[
    <TileColor>[c, e, m],
    <TileColor>[e, m, c],
    <TileColor>[m, c, e],
  ]);

  group('frames', () {
    test('a move that cleared nothing has nothing to play', () {
      expect(
        playback.build(
          swapGrid: a,
          steps: const <CascadeStep>[],
          finalGrid: a,
          events: const <Match3Event>[],
        ),
        isEmpty,
      );
    });

    test('a single match opens on the swapped board and settles on the result',
        () {
      final List<CascadeFrame> frames = playback.build(
        swapGrid: a,
        steps: <CascadeStep>[
          stepWith(cleared: <GridPos>{const GridPos(0, 0)}, boardAfter: b),
        ],
        finalGrid: b,
        events: const <Match3Event>[
          Match3Event(Match3EventType.swap),
          Match3Event(Match3EventType.match, 3, 1),
        ],
      );

      expect(frames, hasLength(2));
      expect(frames.first.grid, same(a),
          reason: 'the player should see the swap land before it resolves');
      expect(frames.first.igniting, <GridPos>{const GridPos(0, 0)});
      expect(frames.last.grid, same(b));
      expect(frames.last.igniting, isEmpty);
    });

    test('each step is its own frame', () {
      final List<CascadeFrame> frames = playback.build(
        swapGrid: a,
        steps: <CascadeStep>[
          stepWith(cleared: <GridPos>{const GridPos(0, 0)}, boardAfter: b),
          stepWith(
            cleared: <GridPos>{const GridPos(1, 1)},
            boardAfter: d,
            level: 2,
          ),
        ],
        finalGrid: d,
        events: const <Match3Event>[
          Match3Event(Match3EventType.swap),
          Match3Event(Match3EventType.match, 3, 1),
          Match3Event(Match3EventType.match, 3, 2),
        ],
      );

      // Swap board, then one board per step.
      expect(frames, hasLength(3));
      expect(frames[1].grid, same(b));
      expect(frames[2].grid, same(d));
      // Each frame announces what is about to go on the board it is showing.
      expect(frames[1].igniting, <GridPos>{const GridPos(1, 1)});
    });

    test('events land on the frame that shows what they describe', () {
      final List<CascadeFrame> frames = playback.build(
        swapGrid: a,
        steps: <CascadeStep>[
          stepWith(cleared: <GridPos>{const GridPos(0, 0)}, boardAfter: b),
          stepWith(
            cleared: <GridPos>{const GridPos(1, 1)},
            boardAfter: d,
            level: 2,
          ),
        ],
        finalGrid: d,
        events: const <Match3Event>[
          Match3Event(Match3EventType.swap),
          Match3Event(Match3EventType.match, 3, 1),
          Match3Event.spawned(SpecialKind.lineHorizontal),
          Match3Event(Match3EventType.match, 4, 2),
          Match3Event(Match3EventType.roundComplete, 1, 6),
        ],
      );

      expect(
        frames[0].events.map((Match3Event ev) => ev.type),
        <Match3EventType>[Match3EventType.swap],
      );
      // The bonus gem belongs with the match that earned it, not with the swap.
      expect(
        frames[1].events.map((Match3Event ev) => ev.type),
        <Match3EventType>[
          Match3EventType.match,
          Match3EventType.specialSpawned,
        ],
      );
      expect(
        frames[2].events.map((Match3Event ev) => ev.type),
        contains(Match3EventType.match),
      );
      // The round payout is announced against the settled board.
      expect(
        frames.last.events.map((Match3Event ev) => ev.type),
        contains(Match3EventType.roundComplete),
      );
    });

    test('every event the move produced is released exactly once', () {
      const List<Match3Event> events = <Match3Event>[
        Match3Event(Match3EventType.swap),
        Match3Event(Match3EventType.match, 3, 1),
        Match3Event.spawned(SpecialKind.bomb),
        Match3Event(Match3EventType.match, 5, 2),
        Match3Event(Match3EventType.roundComplete, 2, 6),
        Match3Event(Match3EventType.gameOver),
      ];
      final List<CascadeFrame> frames = playback.build(
        swapGrid: a,
        steps: <CascadeStep>[
          stepWith(cleared: <GridPos>{const GridPos(0, 0)}, boardAfter: b),
          stepWith(
            cleared: <GridPos>{const GridPos(1, 1)},
            boardAfter: d,
            level: 2,
          ),
        ],
        finalGrid: d,
        events: events,
      );

      final List<Match3Event> released = <Match3Event>[
        for (final CascadeFrame f in frames) ...f.events,
      ];
      expect(released, hasLength(events.length));
      expect(released.toSet(), events.toSet());
    });

    test('the burst carries the colours of the step that just cleared', () {
      final List<CascadeFrame> frames = playback.build(
        swapGrid: a,
        steps: <CascadeStep>[
          stepWith(
            cleared: <GridPos>{const GridPos(0, 0)},
            boardAfter: b,
            colors: <GridPos, TileColor>{const GridPos(0, 0): r},
          ),
        ],
        finalGrid: b,
        events: const <Match3Event>[Match3Event(Match3EventType.match, 3, 1)],
      );

      // The tiles are gone by the time this board is drawn, so the colours
      // cannot be read back off it.
      expect(frames[0].burst, isEmpty);
      expect(frames[1].burst, <GridPos, TileColor>{const GridPos(0, 0): r});
    });
  });

  group('timing', () {
    List<CascadeFrame> chainOf(int depth, {bool combo = false}) {
      return playback.build(
        swapGrid: a,
        steps: <CascadeStep>[
          for (int i = 0; i < depth; i++)
            stepWith(
              cleared: <GridPos>{GridPos(i % 3, i % 3)},
              boardAfter: i.isEven ? b : d,
              level: i + 1,
            ),
        ],
        finalGrid: d,
        events: <Match3Event>[
          const Match3Event(Match3EventType.swap),
          if (combo) const Match3Event.combined(ComboKind.megaBomb),
          for (int i = 0; i < depth; i++)
            Match3Event(Match3EventType.match, 3, i + 1),
        ],
      );
    }

    test('the opening beat is the longest of the chain', () {
      final List<CascadeFrame> frames = chainOf(4);
      for (int i = 1; i < frames.length - 1; i++) {
        expect(
          frames[i].hold,
          lessThan(frames.first.hold),
          reason: 'chain link $i should be quicker than the opening match',
        );
      }
    });

    test('a deep chain accelerates but never below the floor', () {
      final List<CascadeFrame> frames = chainOf(10);
      Duration previous = frames[1].hold;
      for (int i = 2; i < frames.length - 1; i++) {
        expect(frames[i].hold, lessThanOrEqualTo(previous));
        expect(
          frames[i].hold,
          greaterThanOrEqualTo(playback.minimumHold),
          reason: 'a long cascade should build, not blur',
        );
        previous = frames[i].hold;
      }
    });

    test('a combo gets a longer opening than an ordinary match', () {
      expect(chainOf(2, combo: true).first.hold,
          greaterThan(chainOf(2).first.hold));
    });
  });
}
