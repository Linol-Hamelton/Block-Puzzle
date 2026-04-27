import 'dart:math';

import '../gameplay/board_state.dart';
import '../gameplay/piece.dart';
import 'difficulty_profile.dart';
import 'piece_generation_service.dart';
import 'piece_triplet.dart';

class BasicPieceGenerationService implements PieceGenerationService {
  BasicPieceGenerationService({
    Random? random,
  }) : _random = random ?? Random();

  final Random _random;
  int _idSequence = 0;

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

    final List<Piece> result = <Piece>[];
    int hardUsed = 0;

    while (result.length < 3) {
      final bool hardCandidateAllowed =
          hardUsed < runtimeBalance.maxHardPiecesPerTriplet;
      final bool pickHard = hardCandidateAllowed &&
          _random.nextDouble() < runtimeBalance.hardPieceWeight;

      final _PieceTemplate template = _pickTemplate(
        hard: pickHard,
      );
      if (template.isHard) {
        hardUsed += 1;
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

  _PieceTemplate _pickTemplate({
    required bool hard,
  }) {
    final List<_PieceTemplate> pool = hard ? _hardTemplates : _easyTemplates;
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
