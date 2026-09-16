import '../../../domain/match3/cascade_resolver.dart';
import '../../../domain/match3/match3_engine.dart';
import '../../../domain/match3/tile.dart';
import '../../../domain/match3/tile_grid.dart';

/// One board the player is shown while a cascade plays out.
class CascadeFrame {
  const CascadeFrame({
    required this.grid,
    required this.igniting,
    required this.events,
    required this.hold,
    this.burst = const <GridPos, TileColor>{},
  });

  /// The board on screen for this frame.
  final TileGrid grid;

  /// Cells that are about to go. They charge up over the frame, so the clear
  /// is something the player watches happen rather than something that has
  /// already happened by the time they look.
  final Set<GridPos> igniting;

  /// Model events released as this frame begins, so a caption lands with the
  /// thing it is describing instead of ahead of it.
  final List<Match3Event> events;

  /// Cells that cleared on the way *into* this frame, with the colour each held
  /// when it went. The particles belong to the moment of the clear, and by the
  /// time this board is on screen those tiles are gone - so their colours have
  /// to be carried here rather than read back off the grid.
  final Map<GridPos, TileColor> burst;

  final Duration hold;
}

/// Turns one resolved swap into the sequence of boards that shows how it
/// resolved.
///
/// The engine settles a whole cascade inside a single call to `swap`, which is
/// right for the rules and wrong for the eye: a four-step chain reached the
/// screen as one instant jump, indistinguishable from a plain three-in-a-row.
/// The steps carry their intermediate boards, so the same move can be replayed
/// at a speed a person can follow.
///
/// Timing is deliberately uneven. The opening match gets the longest beat
/// because it is the one the player caused; the chain then accelerates, which
/// is what makes a long cascade feel like it is running away rather than
/// dragging. A combo is given its own longer beat - it is the rarest thing in
/// the mode and it should not flash past at chain speed.
class CascadePlayback {
  const CascadePlayback({
    this.openingHold = const Duration(milliseconds: 300),
    this.chainHold = const Duration(milliseconds: 230),
    this.minimumHold = const Duration(milliseconds: 150),
    this.comboHold = const Duration(milliseconds: 460),
    this.settleHold = const Duration(milliseconds: 180),
  });

  final Duration openingHold;
  final Duration chainHold;
  final Duration minimumHold;
  final Duration comboHold;
  final Duration settleHold;

  /// Builds the frames for a move.
  ///
  /// [swapGrid] is the board the instant the exchange landed, [steps] are the
  /// cascade's steps in order, [finalGrid] the settled board, and [events] every
  /// event the move produced, in engine order.
  ///
  /// Returns an empty list when there is nothing to play - a move that cleared
  /// nothing, or a restore - and the caller should simply show [finalGrid].
  List<CascadeFrame> build({
    required TileGrid swapGrid,
    required List<CascadeStep> steps,
    required TileGrid finalGrid,
    required List<Match3Event> events,
  }) {
    if (steps.isEmpty) {
      return const <CascadeFrame>[];
    }

    final _EventSplit split = _EventSplit(events, steps.length);
    final List<CascadeFrame> frames = <CascadeFrame>[];

    // Frame zero: the swap has landed and the first match is charging up.
    frames.add(CascadeFrame(
      grid: swapGrid,
      igniting: steps.first.cleared,
      events: split.opening,
      hold: split.hasCombo ? comboHold : openingHold,
    ));

    for (int i = 0; i < steps.length; i++) {
      final bool isLast = i == steps.length - 1;
      frames.add(CascadeFrame(
        grid: steps[i].boardAfter,
        igniting: isLast ? const <GridPos>{} : steps[i + 1].cleared,
        events: split.forStep(i),
        burst: steps[i].clearedColors,
        // Each link in the chain is a little quicker than the last, down to a
        // floor: a ten-deep cascade should build, not outstay its welcome.
        hold: isLast
            ? settleHold
            : _decayed(chainHold, i),
      ));
    }

    // The settled board, carrying whatever the move concluded with - a round
    // payout, the end of the run.
    if (split.closing.isNotEmpty) {
      frames.add(CascadeFrame(
        grid: finalGrid,
        igniting: const <GridPos>{},
        events: split.closing,
        hold: settleHold,
      ));
    }

    return frames;
  }

  Duration _decayed(Duration base, int depth) {
    final int ms = (base.inMilliseconds * _falloff(depth)).round();
    return Duration(
      milliseconds: ms < minimumHold.inMilliseconds
          ? minimumHold.inMilliseconds
          : ms,
    );
  }

  static double _falloff(int depth) {
    double factor = 1;
    for (int i = 0; i < depth; i++) {
      factor *= 0.86;
    }
    return factor;
  }
}

/// Splits one move's events into the frame each belongs to.
///
/// The engine emits them in one flat run: the swap, then a match event per
/// cascade step with the bonus gems that step earned, then whatever the move
/// concluded with. Released all at once they describe a board the player has
/// not been shown yet.
class _EventSplit {
  _EventSplit(List<Match3Event> events, int stepCount)
      : _perStep = List<List<Match3Event>>.generate(
          stepCount,
          (_) => <Match3Event>[],
          growable: false,
        ) {
    int step = -1;
    for (final Match3Event event in events) {
      switch (event.type) {
        case Match3EventType.swap:
        case Match3EventType.invalidSwap:
          opening.add(event);
        case Match3EventType.combo:
          hasCombo = true;
          opening.add(event);
        case Match3EventType.match:
          step += 1;
          if (step < _perStep.length) {
            _perStep[step].add(event);
          } else {
            closing.add(event);
          }
        case Match3EventType.specialSpawned:
          // Belongs with the match that earned it.
          if (step >= 0 && step < _perStep.length) {
            _perStep[step].add(event);
          } else {
            closing.add(event);
          }
        case Match3EventType.roundComplete:
        case Match3EventType.shuffle:
        case Match3EventType.gameOver:
          closing.add(event);
      }
    }
  }

  final List<Match3Event> opening = <Match3Event>[];
  final List<Match3Event> closing = <Match3Event>[];
  final List<List<Match3Event>> _perStep;
  bool hasCombo = false;

  List<Match3Event> forStep(int index) =>
      index >= 0 && index < _perStep.length
          ? _perStep[index]
          : const <Match3Event>[];
}
