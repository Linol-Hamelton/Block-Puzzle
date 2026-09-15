import 'dart:math';

/// A pseudo-random generator whose state can be read and restored.
///
/// `dart:math`'s [Random] keeps its state private, so a game that draws from it
/// cannot be saved and resumed without changing what happens next. That is
/// exactly what went wrong: restoring a Tetris run produced a different piece
/// queue, and restoring a Match-3 board made the same swap resolve differently,
/// because the snapshot carried the board but not the generator that feeds it.
///
/// This implements [Random], so `list.shuffle(rng)` and the rest keep working,
/// while [state] can be serialised alongside the board.
///
/// The algorithm is xorshift32. It is not cryptographic and makes no claim to
/// be: it needs to be fast, deterministic, identical on every device, and small
/// enough to store in a snapshot. Anything that must resist a motivated player
/// - scores, entitlements - is validated on the server instead.
class DeterministicRandom implements Random {
  DeterministicRandom(int seed) : _state = _sanitise(seed);

  /// Restores a generator that is mid-sequence.
  DeterministicRandom.fromState(int state) : _state = _sanitise(state);

  int _state;

  /// xorshift32 cycles forever except from zero, which is a fixed point.
  static int _sanitise(int seed) {
    final int masked = seed & 0xFFFFFFFF;
    return masked == 0 ? 0x9E3779B9 : masked;
  }

  /// The full state, which is all that is needed to continue the sequence.
  int get state => _state;

  int _advance() {
    int x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    return _state = x & 0xFFFFFFFF;
  }

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw RangeError.range(max, 1, null, 'max');
    }
    // Rejection sampling rather than a plain modulo, so small ranges are not
    // biased towards their low values. With a 32-bit generator and the ranges
    // this game uses - seven tetrominoes, six tile colours - a rejection is
    // vanishingly rare, but the bias would otherwise be permanent and silent.
    final int limit = 0x100000000 - (0x100000000 % max);
    int draw;
    do {
      draw = _advance();
    } while (draw >= limit);
    return draw % max;
  }

  @override
  double nextDouble() => _advance() / 0x100000000;

  @override
  bool nextBool() => _advance().isOdd;
}
