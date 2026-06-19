import 'dart:math';

import 'tetromino.dart';

/// Standard 7-bag randomizer: every permutation of the seven tetrominoes is
/// dealt once before any repeats, guaranteeing fair distribution and bounded
/// droughts. Accepts an optional [seed] for deterministic sequences (daily
/// challenge / leaderboard parity).
class SevenBagRandomizer {
  SevenBagRandomizer({int? seed}) : _random = Random(seed);

  final Random _random;
  final List<TetrominoType> _queue = <TetrominoType>[];

  /// Dispenses the next tetromino, refilling the bag when empty.
  TetrominoType next() {
    if (_queue.isEmpty) {
      _refill();
    }
    return _queue.removeAt(0);
  }

  /// Looks ahead at the next [count] tetrominoes without consuming them
  /// (for the "next" preview), refilling as needed.
  List<TetrominoType> peek(int count) {
    while (_queue.length < count) {
      _refill();
    }
    return _queue.take(count).toList(growable: false);
  }

  void _refill() {
    final List<TetrominoType> bag = List<TetrominoType>.of(
      Tetromino.spawnOrder,
    )..shuffle(_random);
    _queue.addAll(bag);
  }
}
