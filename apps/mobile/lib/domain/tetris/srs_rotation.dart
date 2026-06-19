import 'tetromino.dart';

/// Super Rotation System (SRS) wall-kick data.
///
/// The tables below are transcribed **verbatim** from the Tetris Guideline SRS
/// spec, which uses a coordinate system where **y increases upward**. This
/// project's board uses **y increasing downward**, so [kicksFor] negates the y
/// component of every offset when returning board-space translations. Keeping
/// the raw tables in their canonical orientation makes them directly checkable
/// against the reference; the single conversion point is [kicksFor].
///
/// Rotation indices: 0 = spawn, 1 = R (CW), 2 = 180°, 3 = L (CCW).
/// Only single-step transitions (0↔R, R↔2, 2↔L, L↔0) carry kicks; a 180°
/// rotation uses no kick (just the (0,0) test).
class KickOffset {
  const KickOffset(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is KickOffset && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}

class SrsRotation {
  const SrsRotation._();

  /// Board-space (y-down) kick tests for rotating [type] from rotation [from]
  /// to rotation [to]. The first test is always (0,0). Returns a single
  /// (0,0) test for 180° turns and for the O piece.
  static List<KickOffset> kicksFor(TetrominoType type, int from, int to) {
    final int f = from & 3;
    final int t = to & 3;
    if (type == TetrominoType.o) {
      return const <KickOffset>[KickOffset(0, 0)];
    }
    final Map<int, List<KickOffset>> table =
        type == TetrominoType.i ? _iKicksYUp : _jlstzKicksYUp;
    final List<KickOffset>? raw = table[_key(f, t)];
    if (raw == null) {
      // Non-adjacent (e.g. 180°) or unknown transition: no kick.
      return const <KickOffset>[KickOffset(0, 0)];
    }
    // Convert canonical y-up offsets to board-space y-down.
    return raw
        .map((KickOffset k) => KickOffset(k.x, -k.y))
        .toList(growable: false);
  }

  static int _key(int from, int to) => (from << 2) | to;

  // ── JLSTZ kicks (canonical, y-up) ──
  static const Map<int, List<KickOffset>> _jlstzKicksYUp =
      <int, List<KickOffset>>{
    0x1: <KickOffset>[ // 0 -> R
      KickOffset(0, 0), KickOffset(-1, 0), KickOffset(-1, 1),
      KickOffset(0, -2), KickOffset(-1, -2),
    ],
    0x4: <KickOffset>[ // R -> 0
      KickOffset(0, 0), KickOffset(1, 0), KickOffset(1, -1),
      KickOffset(0, 2), KickOffset(1, 2),
    ],
    0x6: <KickOffset>[ // R -> 2
      KickOffset(0, 0), KickOffset(1, 0), KickOffset(1, -1),
      KickOffset(0, 2), KickOffset(1, 2),
    ],
    0x9: <KickOffset>[ // 2 -> R
      KickOffset(0, 0), KickOffset(-1, 0), KickOffset(-1, 1),
      KickOffset(0, -2), KickOffset(-1, -2),
    ],
    0xB: <KickOffset>[ // 2 -> L
      KickOffset(0, 0), KickOffset(1, 0), KickOffset(1, 1),
      KickOffset(0, -2), KickOffset(1, -2),
    ],
    0xE: <KickOffset>[ // L -> 2
      KickOffset(0, 0), KickOffset(-1, 0), KickOffset(-1, -1),
      KickOffset(0, 2), KickOffset(-1, 2),
    ],
    0xC: <KickOffset>[ // L -> 0
      KickOffset(0, 0), KickOffset(-1, 0), KickOffset(-1, -1),
      KickOffset(0, 2), KickOffset(-1, 2),
    ],
    0x3: <KickOffset>[ // 0 -> L
      KickOffset(0, 0), KickOffset(1, 0), KickOffset(1, 1),
      KickOffset(0, -2), KickOffset(1, -2),
    ],
  };

  // ── I kicks (canonical, y-up) ──
  static const Map<int, List<KickOffset>> _iKicksYUp = <int, List<KickOffset>>{
    0x1: <KickOffset>[ // 0 -> R
      KickOffset(0, 0), KickOffset(-2, 0), KickOffset(1, 0),
      KickOffset(-2, -1), KickOffset(1, 2),
    ],
    0x4: <KickOffset>[ // R -> 0
      KickOffset(0, 0), KickOffset(2, 0), KickOffset(-1, 0),
      KickOffset(2, 1), KickOffset(-1, -2),
    ],
    0x6: <KickOffset>[ // R -> 2
      KickOffset(0, 0), KickOffset(-1, 0), KickOffset(2, 0),
      KickOffset(-1, 2), KickOffset(2, -1),
    ],
    0x9: <KickOffset>[ // 2 -> R
      KickOffset(0, 0), KickOffset(1, 0), KickOffset(-2, 0),
      KickOffset(1, -2), KickOffset(-2, 1),
    ],
    0xB: <KickOffset>[ // 2 -> L
      KickOffset(0, 0), KickOffset(2, 0), KickOffset(-1, 0),
      KickOffset(2, 1), KickOffset(-1, -2),
    ],
    0xE: <KickOffset>[ // L -> 2
      KickOffset(0, 0), KickOffset(-2, 0), KickOffset(1, 0),
      KickOffset(-2, -1), KickOffset(1, 2),
    ],
    0xC: <KickOffset>[ // L -> 0
      KickOffset(0, 0), KickOffset(1, 0), KickOffset(-2, 0),
      KickOffset(1, -2), KickOffset(-2, 1),
    ],
    0x3: <KickOffset>[ // 0 -> L
      KickOffset(0, 0), KickOffset(-1, 0), KickOffset(2, 0),
      KickOffset(-1, 2), KickOffset(2, -1),
    ],
  };
}
