import '../shared/deterministic_random.dart';
import 'tetromino.dart';

/// Standard 7-bag randomizer: every permutation of the seven tetrominoes is
/// dealt once before any repeats, guaranteeing fair distribution and bounded
/// droughts. Accepts an optional [seed] for deterministic sequences (daily
/// challenge / leaderboard parity).
///
/// Both the generator state and the pending queue are serialisable. Without
/// that, resuming a run changed which pieces arrived next: the snapshot carried
/// the board but not the bag, so the engine restarted the sequence from a fresh
/// generator. A player who backgrounded the app got a different game back.
class SevenBagRandomizer {
  SevenBagRandomizer({int? seed}) : this._withSeed(seed ?? _freshSeed());

  SevenBagRandomizer._withSeed(int seed)
      : _seed = seed,
        _random = DeterministicRandom(seed);

  SevenBagRandomizer._restored({
    required int seed,
    required int state,
    required List<TetrominoType> queue,
  })  : _seed = seed,
        _random = DeterministicRandom.fromState(state) {
    _queue.addAll(queue);
  }

  /// A seed is always recorded, even when the caller did not supply one.
  /// A run started without an explicit seed still has to be resumable.
  static int _freshSeed() => DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;

  final int _seed;
  final DeterministicRandom _random;
  final List<TetrominoType> _queue = <TetrominoType>[];

  int get seed => _seed;

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

  /// Everything needed to continue the same sequence after a restart.
  Map<String, Object?> toJson() => <String, Object?>{
        'seed': _seed,
        'state': _random.state,
        'queue': _queue.map((TetrominoType type) => type.name).toList(
              growable: false,
            ),
      };

  /// Rebuilds a randomizer mid-sequence. Falls back to a fresh one when the
  /// payload is missing or malformed, which is better than refusing to resume.
  static SevenBagRandomizer fromJson(Map<String, Object?>? json) {
    if (json == null) {
      return SevenBagRandomizer();
    }
    final Object? seed = json['seed'];
    final Object? state = json['state'];
    if (seed is! int || state is! int) {
      return SevenBagRandomizer();
    }
    final List<TetrominoType> queue = <TetrominoType>[];
    final Object? rawQueue = json['queue'];
    if (rawQueue is List) {
      for (final Object? entry in rawQueue) {
        final TetrominoType? type = _typeFromName(entry);
        if (type != null) {
          queue.add(type);
        }
      }
    }
    return SevenBagRandomizer._restored(
      seed: seed,
      state: state,
      queue: queue,
    );
  }

  static TetrominoType? _typeFromName(Object? name) {
    if (name is! String) {
      return null;
    }
    for (final TetrominoType type in TetrominoType.values) {
      if (type.name == name) {
        return type;
      }
    }
    return null;
  }
}
