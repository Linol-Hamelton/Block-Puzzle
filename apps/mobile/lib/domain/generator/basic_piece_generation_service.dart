import 'dart:math';

import '../gameplay/basic_move_validator.dart';
import '../gameplay/board_state.dart';
import '../gameplay/move.dart';
import '../gameplay/move_validator.dart';
import '../gameplay/piece.dart';
import '../gameplay/validation_result.dart';
import 'difficulty_profile.dart';
import 'piece_generation_service.dart';
import 'piece_triplet.dart';

class BasicPieceGenerationService implements PieceGenerationService {
  BasicPieceGenerationService({
    Random? random,
    MoveValidator? moveValidator,
  })  : _random = random ?? Random(),
        _moveValidator = moveValidator ?? const BasicMoveValidator();

  Random _random;
  final MoveValidator _moveValidator;
  int _idSequence = 0;

  static const int maxFairAttempts = 10;

  @override
  void setSeed(int? seed) {
    if (seed == null) {
      _random = Random();
    } else {
      _random = Random(seed);
    }
    // Also reset id sequence so IDs are deterministic for the same seed
    _idSequence = 0;
  }

  static const List<_PieceTemplate> _easyTemplates = <_PieceTemplate>[
    _PieceTemplate(
      key: 'dot',
      cells: <PieceCellOffset>[PieceCellOffset(dx: 0, dy: 0)],
      isHard: false,
    ),
    _PieceTemplate(
      key: 'line2',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 0, dy: 0),
        PieceCellOffset(dx: 1, dy: 0),
      ],
      isHard: false,
    ),
    _PieceTemplate(
      key: 'line3',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 0, dy: 0),
        PieceCellOffset(dx: 1, dy: 0),
        PieceCellOffset(dx: 2, dy: 0),
      ],
      isHard: false,
    ),
    _PieceTemplate(
      key: 'vline3',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 0, dy: 0),
        PieceCellOffset(dx: 0, dy: 1),
        PieceCellOffset(dx: 0, dy: 2),
      ],
      isHard: false,
    ),
    _PieceTemplate(
      key: 'square2',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 0, dy: 0),
        PieceCellOffset(dx: 1, dy: 0),
        PieceCellOffset(dx: 0, dy: 1),
        PieceCellOffset(dx: 1, dy: 1),
      ],
      isHard: false,
    ),
    _PieceTemplate(
      key: 'l3',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 0, dy: 0),
        PieceCellOffset(dx: 0, dy: 1),
        PieceCellOffset(dx: 1, dy: 1),
      ],
      isHard: false,
    ),
  ];

  static const List<_PieceTemplate> _hardTemplates = <_PieceTemplate>[
    _PieceTemplate(
      key: 'line4',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 0, dy: 0),
        PieceCellOffset(dx: 1, dy: 0),
        PieceCellOffset(dx: 2, dy: 0),
        PieceCellOffset(dx: 3, dy: 0),
      ],
      isHard: true,
    ),
    _PieceTemplate(
      key: 'line5',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 0, dy: 0),
        PieceCellOffset(dx: 1, dy: 0),
        PieceCellOffset(dx: 2, dy: 0),
        PieceCellOffset(dx: 3, dy: 0),
        PieceCellOffset(dx: 4, dy: 0),
      ],
      isHard: true,
    ),
    _PieceTemplate(
      key: 'big_l',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 0, dy: 0),
        PieceCellOffset(dx: 0, dy: 1),
        PieceCellOffset(dx: 0, dy: 2),
        PieceCellOffset(dx: 1, dy: 2),
      ],
      isHard: true,
    ),
    _PieceTemplate(
      key: 'tee4',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 0, dy: 0),
        PieceCellOffset(dx: 1, dy: 0),
        PieceCellOffset(dx: 2, dy: 0),
        PieceCellOffset(dx: 1, dy: 1),
      ],
      isHard: true,
    ),
    _PieceTemplate(
      key: 'zig4',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 0, dy: 1),
        PieceCellOffset(dx: 1, dy: 1),
        PieceCellOffset(dx: 1, dy: 0),
        PieceCellOffset(dx: 2, dy: 0),
      ],
      isHard: true,
    ),
    _PieceTemplate(
      key: 'vline4',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 0, dy: 0),
        PieceCellOffset(dx: 0, dy: 1),
        PieceCellOffset(dx: 0, dy: 2),
        PieceCellOffset(dx: 0, dy: 3),
      ],
      isHard: true,
    ),
    _PieceTemplate(
      key: 'vline5',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 0, dy: 0),
        PieceCellOffset(dx: 0, dy: 1),
        PieceCellOffset(dx: 0, dy: 2),
        PieceCellOffset(dx: 0, dy: 3),
        PieceCellOffset(dx: 0, dy: 4),
      ],
      isHard: true,
    ),
    _PieceTemplate(
      key: 'square3',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 0, dy: 0), PieceCellOffset(dx: 1, dy: 0), PieceCellOffset(dx: 2, dy: 0),
        PieceCellOffset(dx: 0, dy: 1), PieceCellOffset(dx: 1, dy: 1), PieceCellOffset(dx: 2, dy: 1),
        PieceCellOffset(dx: 0, dy: 2), PieceCellOffset(dx: 1, dy: 2), PieceCellOffset(dx: 2, dy: 2),
      ],
      isHard: true,
    ),
    _PieceTemplate(
      key: 'cross5',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 1, dy: 0),
        PieceCellOffset(dx: 0, dy: 1), PieceCellOffset(dx: 1, dy: 1), PieceCellOffset(dx: 2, dy: 1),
        PieceCellOffset(dx: 1, dy: 2),
      ],
      isHard: true,
    ),
    _PieceTemplate(
      key: 'corner5',
      cells: <PieceCellOffset>[
        PieceCellOffset(dx: 0, dy: 0),
        PieceCellOffset(dx: 0, dy: 1),
        PieceCellOffset(dx: 0, dy: 2), PieceCellOffset(dx: 1, dy: 2), PieceCellOffset(dx: 2, dy: 2),
      ],
      isHard: true,
    ),
  ];

  @override
  PieceTriplet nextTriplet({
    required BoardState boardState,
    required DifficultyProfile profile,
  }) {
    final double fillRatio =
        boardState.occupiedCells.length / (boardState.size * boardState.size);
    final _RuntimeBalance runtimeBalance = _resolveRuntimeBalance(
      fillRatio: fillRatio,
      profile: profile,
    );

    // DEC-0028 Item 16: Anti-chunking at board fill > 50%
    final bool antiChunkingActive = fillRatio > 0.50;
    final List<Piece> result = <Piece>[];
    int hardUsed = 0;
    int heavyUsed = 0;

    // Piece 0 (First piece): Fair Bag guarantee.
    // The first piece of a dealt triplet is guaranteed mathematically placeable
    // against the current board at deal time.
    final bool firstPickHard = runtimeBalance.maxHardPiecesPerTriplet > 0 &&
        _random.nextDouble() < runtimeBalance.hardPieceWeight;
    _PieceTemplate firstTemplate = _pickTemplate(
      hard: firstPickHard,
      disallowHeavy: false,
    );

    if (!_canPlaceTemplate(boardState, firstTemplate)) {
      bool foundPlaceable = false;
      for (int attempt = 0; attempt < maxFairAttempts; attempt++) {
        final _PieceTemplate candidate = _pickTemplate(
          hard: false,
        );
        if (_canPlaceTemplate(boardState, candidate)) {
          firstTemplate = candidate;
          foundPlaceable = true;
          break;
        }
      }

      // Deterministic fallback if random retry budget is exhausted:
      // Walk through easy templates in fixed deterministic order.
      if (!foundPlaceable) {
        for (final _PieceTemplate fallback in _easyTemplates) {
          if (_canPlaceTemplate(boardState, fallback)) {
            firstTemplate = fallback;
            foundPlaceable = true;
            break;
          }
        }
      }

      // If even deterministic fallback cannot place any piece (e.g. board 100% full),
      // keep the fallback piece ('dot') so the deal safely terminates.
      if (!foundPlaceable) {
        firstTemplate = _easyTemplates.first;
      }
    }

    if (firstTemplate.isHard) {
      hardUsed += 1;
    }
    if (_isHeavyTemplate(firstTemplate)) {
      heavyUsed += 1;
    }
    result.add(
      Piece(
        id: '${firstTemplate.key}_${_idSequence++}',
        cells: firstTemplate.cells,
      ),
    );

    // Pieces 1 and 2: Standard deal with anti-chunking guard.
    // Placing the first piece may make pieces 2 and 3 unplaceable, and that is fair.
    while (result.length < 3) {
      final bool hardCandidateAllowed =
          hardUsed < runtimeBalance.maxHardPiecesPerTriplet;
      final bool pickHard = hardCandidateAllowed &&
          _random.nextDouble() < runtimeBalance.hardPieceWeight;
      final bool disallowHeavy = antiChunkingActive && heavyUsed >= 1;

      final _PieceTemplate template = _pickTemplate(
        hard: pickHard,
        disallowHeavy: disallowHeavy,
      );
      if (template.isHard) {
        hardUsed += 1;
      }
      if (_isHeavyTemplate(template)) {
        heavyUsed += 1;
      }

      result.add(
        Piece(
          id: '${template.key}_${_idSequence++}',
          cells: template.cells,
        ),
      );
    }

    return PieceTriplet(pieces: result);
  }

  bool _canPlaceTemplate(BoardState boardState, _PieceTemplate template) {
    final Piece testPiece = Piece(id: 'probe', cells: template.cells);
    for (int y = 0; y < boardState.size; y++) {
      for (int x = 0; x < boardState.size; x++) {
        final ValidationResult result = _moveValidator.validate(
          boardState: boardState,
          move: Move(piece: testPiece, anchorX: x, anchorY: y),
        );
        if (result.isValid) {
          return true;
        }
      }
    }
    return false;
  }

  _RuntimeBalance _resolveRuntimeBalance({
    required double fillRatio,
    required DifficultyProfile profile,
  }) {
    double hardWeight = profile.hardPieceWeight;
    int maxHard = profile.maxHardPiecesPerTriplet;

    if (fillRatio >= 0.75) {
      hardWeight *= 0.35;
      maxHard = maxHard > 1 ? 1 : maxHard;
    } else if (fillRatio >= 0.55) {
      hardWeight *= 0.6;
    } else if (fillRatio <= 0.20) {
      hardWeight += 0.08;
    }

    return _RuntimeBalance(
      hardPieceWeight: hardWeight.clamp(0.05, 0.90),
      maxHardPiecesPerTriplet: maxHard.clamp(0, 3),
    );
  }

  static bool _isHeavyTemplate(_PieceTemplate template) {
    return template.key == 'square3' ||
        template.key == 'line5' ||
        template.key == 'vline5';
  }

  _PieceTemplate _pickTemplate({
    required bool hard,
    bool disallowHeavy = false,
  }) {
    List<_PieceTemplate> pool = hard ? _hardTemplates : _easyTemplates;
    if (hard && disallowHeavy) {
      pool = _hardTemplates
          .where((_PieceTemplate t) => !_isHeavyTemplate(t))
          .toList(growable: false);
    }
    return pool[_random.nextInt(pool.length)];
  }
}

class _PieceTemplate {
  const _PieceTemplate({
    required this.key,
    required this.cells,
    required this.isHard,
  });

  final String key;
  final List<PieceCellOffset> cells;
  final bool isHard;
}

class _RuntimeBalance {
  const _RuntimeBalance({
    required this.hardPieceWeight,
    required this.maxHardPiecesPerTriplet,
  });

  final double hardPieceWeight;
  final int maxHardPiecesPerTriplet;
}
