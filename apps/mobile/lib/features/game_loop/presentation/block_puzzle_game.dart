import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../../../domain/gameplay/board_state.dart';
import '../../../domain/gameplay/move.dart';
import '../../../domain/gameplay/piece.dart';
import '../audio/game_sfx_player.dart';
import '../application/game_loop_controller.dart';
import '../application/game_loop_view_state.dart';

class BlockPuzzleGame extends FlameGame {
  static const double _touchDragLiftPixels = 50;

  BlockPuzzleGame({
    required this.controller,
    required this.sfxPlayer,
  });

  final GameLoopController controller;
  final GameSfxPlayer sfxPlayer;

  final BoardComponent _boardComponent = BoardComponent();
  final List<RackPieceComponent> _rackComponents = <RackPieceComponent>[];
  VoidCallback? _stateListener;
  String _rackSignature = '';
  bool _isShuttingDown = false;

  double _boardCellSize = 36;
  Vector2 _boardOrigin = Vector2.zero();
  bool _dropInProgress = false;

  double _rackCellSize = 24;
  double _rackMinTouchTargetSize = 48;
  double _dragActivationDistance = 9;
  double _boardMaxPixels = 420;
  double _boardMinPixels = 220;
  double _boardToRackGap = 18;
  double _layoutHorizontalPadding = 20;
  double _layoutTopInset = 124;
  double _layoutBottomInset = 120;
  double _rackTop = 0;
  double _rackReservedHeight = 108;
  bool _pendingRackRebuild = false;
  BlockVisualPreset _visualPreset = BlockVisualPreset.soft;
  static const List<_BoardPalette> _palettes = <_BoardPalette>[
    _BoardPalette(
      boardBackground: Color(0xFF0C1B36),
      occupiedColor: Color(0xFF55CEFF),
      rackColor: Color(0xFF4ABEEA),
      rackDragColor: Color(0xFF77DEFF),
    ),
    _BoardPalette(
      boardBackground: Color(0xFF101E3C),
      occupiedColor: Color(0xFF9580FF),
      rackColor: Color(0xFF8570EE),
      rackDragColor: Color(0xFFB2A5FF),
    ),
    _BoardPalette(
      boardBackground: Color(0xFF102241),
      occupiedColor: Color(0xFFFFA369),
      rackColor: Color(0xFFF19356),
      rackDragColor: Color(0xFFFFBD90),
    ),
    _BoardPalette(
      boardBackground: Color(0xFF0E1E3A),
      occupiedColor: Color(0xFF70D8FF),
      rackColor: Color(0xFF5CC9F0),
      rackDragColor: Color(0xFF8EE5FF),
    ),
    _BoardPalette(
      boardBackground: Color(0xFF121F3F),
      occupiedColor: Color(0xFFAA8CFF),
      rackColor: Color(0xFF9575F3),
      rackDragColor: Color(0xFFC6B4FF),
    ),
    _BoardPalette(
      boardBackground: Color(0xFF0E1E3B),
      occupiedColor: Color(0xFFFFB071),
      rackColor: Color(0xFFF79D62),
      rackDragColor: Color(0xFFFFCCA0),
    ),
  ];

  @override
  Color backgroundColor() => const Color(0xFF060E24);

  int _activePaletteIndex = 0;
  int _previousPaletteIndex = 0;
  double _paletteTransition = 1;

  @override
  Future<void> onLoad() async {
    await sfxPlayer.preload();
    await controller.initialize();

    if (_isShuttingDown) {
      return;
    }

    add(_boardComponent);

    _stateListener = _syncWithState;
    controller.stateListenable.addListener(_stateListener!);
    _syncWithState();

    await super.onLoad();
  }

  void configureViewportInsets({
    required double topInset,
    required double bottomInset,
    double? horizontalPadding,
    double? boardMaxPixels,
    double? boardMinPixels,
    double? rackCellSize,
    double? boardToRackGap,
    double? rackMinTouchTargetSize,
    double? dragActivationDistance,
  }) {
    if (_isShuttingDown) {
      return;
    }
    final double normalizedTop = topInset.clamp(84, 300);
    final double normalizedBottom = bottomInset.clamp(84, 320);
    final double normalizedHorizontalPadding =
        (horizontalPadding ?? _layoutHorizontalPadding).clamp(10, 44);
    final double normalizedBoardMax =
        (boardMaxPixels ?? _boardMaxPixels).clamp(260, 700);
    final double normalizedBoardMin =
        (boardMinPixels ?? _boardMinPixels).clamp(160, normalizedBoardMax - 16);
    final double normalizedRackCell =
        (rackCellSize ?? _rackCellSize).clamp(18, 36).toDouble();
    final double normalizedBoardToRackGap =
        (boardToRackGap ?? _boardToRackGap).clamp(10, 36);
    final double normalizedRackMinTouchTargetSize =
        (rackMinTouchTargetSize ?? _rackMinTouchTargetSize)
            .clamp(48, 72)
            .toDouble();
    final double normalizedDragActivationDistance =
        (dragActivationDistance ?? _dragActivationDistance)
            .clamp(4, 20)
            .toDouble();
    final bool rackCellChanged =
        (_rackCellSize - normalizedRackCell).abs() > 0.01;
    final bool dragConfigChanged =
        (_rackMinTouchTargetSize - normalizedRackMinTouchTargetSize).abs() >
                0.01 ||
            (_dragActivationDistance - normalizedDragActivationDistance).abs() >
                0.01;

    if ((_layoutTopInset - normalizedTop).abs() < 0.5 &&
        (_layoutBottomInset - normalizedBottom).abs() < 0.5 &&
        (_layoutHorizontalPadding - normalizedHorizontalPadding).abs() < 0.5 &&
        (_boardMaxPixels - normalizedBoardMax).abs() < 0.5 &&
        (_boardMinPixels - normalizedBoardMin).abs() < 0.5 &&
        !rackCellChanged &&
        !dragConfigChanged &&
        (_boardToRackGap - normalizedBoardToRackGap).abs() < 0.5) {
      return;
    }

    _layoutTopInset = normalizedTop;
    _layoutBottomInset = normalizedBottom;
    _layoutHorizontalPadding = normalizedHorizontalPadding;
    _boardMaxPixels = normalizedBoardMax;
    _boardMinPixels = normalizedBoardMin;
    _rackCellSize = normalizedRackCell;
    _boardToRackGap = normalizedBoardToRackGap;
    _rackMinTouchTargetSize = normalizedRackMinTouchTargetSize;
    _dragActivationDistance = normalizedDragActivationDistance;
    if (!hasLayout) {
      if ((rackCellChanged || dragConfigChanged) &&
          _rackComponents.isNotEmpty) {
        _pendingRackRebuild = true;
      }
      return;
    }
    _recalculateLayout();
    if ((rackCellChanged || dragConfigChanged) && _rackComponents.isNotEmpty) {
      _rebuildRackPieces(controller.state.rackPieces);
      return;
    }
    _positionRackPieces();
  }

  @override
  void onGameResize(Vector2 size) {
    if (_isShuttingDown) {
      return;
    }
    super.onGameResize(size);
    _recalculateLayout();
    if (_pendingRackRebuild && _rackComponents.isNotEmpty) {
      _pendingRackRebuild = false;
      _rebuildRackPieces(
        _rackComponents
            .map((RackPieceComponent component) => component.piece)
            .toList(),
      );
      return;
    }
    _positionRackPieces();
  }

  @override
  void update(double dt) {
    if (_isShuttingDown) {
      return;
    }
    super.update(dt);
    if (_paletteTransition >= 1) {
      return;
    }
    _paletteTransition = (_paletteTransition + (dt * 2.1)).clamp(0, 1);
    _applyCurrentPalette();
  }

  @override
  void onRemove() {
    shutdown();
    super.onRemove();
  }

  void shutdown() {
    if (_isShuttingDown) {
      return;
    }
    _isShuttingDown = true;
    pauseEngine();

    final VoidCallback? listener = _stateListener;
    if (listener != null) {
      controller.stateListenable.removeListener(listener);
      _stateListener = null;
    }

    for (final RackPieceComponent component in _rackComponents) {
      component.removeFromParent();
    }
    _rackComponents.clear();
    _rackSignature = '';
    _boardComponent.clearPreview();
    _boardComponent.clearHint();
  }

  void onRackPieceDragged(RackPieceComponent pieceComponent) {
    if (_isShuttingDown) {
      return;
    }
    final _BoardAnchor? anchor = _anchorForPiecePosition(pieceComponent);
    if (anchor == null) {
      _boardComponent.clearPreview();
      return;
    }

    final bool isValid = controller.canPlacePiece(
      piece: pieceComponent.piece,
      anchorX: anchor.x,
      anchorY: anchor.y,
    );

    _boardComponent.setPreview(
      piece: pieceComponent.piece,
      anchorX: anchor.x,
      anchorY: anchor.y,
      valid: isValid,
    );
  }

  Future<void> onRackPieceDropped(RackPieceComponent pieceComponent) async {
    if (_isShuttingDown) {
      pieceComponent.resetToHome();
      _boardComponent.clearPreview();
      return;
    }
    if (_dropInProgress) {
      pieceComponent.resetToHome();
      _boardComponent.clearPreview();
      return;
    }

    final _BoardAnchor? anchor = _anchorForPiecePosition(pieceComponent);
    if (anchor == null) {
      pieceComponent.resetToHome();
      _boardComponent.clearPreview();
      unawaited(sfxPlayer.playInvalidMove());
      return;
    }

    _dropInProgress = true;
    final MoveProcessingResult result = await controller.processMove(
      Move(
        piece: pieceComponent.piece,
        anchorX: anchor.x,
        anchorY: anchor.y,
      ),
    );

    _dropInProgress = false;
    _boardComponent.clearPreview();

    if (!result.isSuccess) {
      pieceComponent.resetToHome();
      unawaited(sfxPlayer.playInvalidMove());
      return;
    }

    unawaited(sfxPlayer.playPiecePlaced());

    if (result.clearedLines > 0) {
      unawaited(sfxPlayer.playLineClear(clearedLines: result.clearedLines));
      _playLineClearAnimation(
        strength: result.clearedLines,
        clearedCells: result.clearedCells,
      );
    }

    if (result.comboStreak > 1) {
      unawaited(sfxPlayer.playCombo(comboStreak: result.comboStreak));
      _playComboAnimation(comboStreak: result.comboStreak);
    }

    if (result.isGameOver) {
      unawaited(sfxPlayer.playGameOver());
    }
  }

  void _syncWithState() {
    if (_isShuttingDown) {
      return;
    }
    final state = controller.state;
    _visualPreset = _blockVisualPresetFromString(controller.blocksVisualPreset);
    _boardComponent.setVisualPreset(_visualPreset);
    _setPaletteFromState(state.colorThemeIndex);
    _boardComponent.setBoardState(state.boardState);
    final HintSuggestion? hintSuggestion = state.hintSuggestion;
    if (hintSuggestion == null) {
      _boardComponent.clearHint();
    } else {
      _boardComponent.setHint(
        piece: hintSuggestion.piece,
        anchorX: hintSuggestion.anchorX,
        anchorY: hintSuggestion.anchorY,
      );
    }
    final String nextRackSignature = _buildRackSignature(state.rackPieces);
    final bool rackChanged = nextRackSignature != _rackSignature;
    if (rackChanged || _rackComponents.length != state.rackPieces.length) {
      _rackSignature = nextRackSignature;
      _rebuildRackPieces(state.rackPieces);
    } else if (_rackComponents.isNotEmpty) {
      _applyCurrentPalette();
    }
    _recalculateLayout();
    _positionRackPieces();
  }

  String _buildRackSignature(List<Piece> pieces) {
    if (pieces.isEmpty) {
      return '';
    }
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < pieces.length; i++) {
      if (i > 0) {
        buffer.write('|');
      }
      buffer.write(pieces[i].id);
    }
    return buffer.toString();
  }

  void _recalculateLayout() {
    if (_isShuttingDown) {
      return;
    }
    if (!hasLayout) {
      return;
    }
    if (size.x <= 0 || size.y <= 0) {
      return;
    }

    final double availableWidth = math.max(
      120,
      size.x - (_layoutHorizontalPadding * 2),
    );
    final double contentTop = _layoutTopInset;
    final double contentBottom = math.max(
      contentTop + 240,
      size.y - _layoutBottomInset,
    );
    final double contentHeight = math.max(
      240,
      contentBottom - contentTop,
    );
    _rackReservedHeight = _estimateRackReservedHeight();
    final double maxBoardByHeight = math.max(
      170,
      contentHeight - _boardToRackGap - _rackReservedHeight,
    );

    double boardPixels = math.min(availableWidth, maxBoardByHeight);
    boardPixels = math.min(boardPixels, _boardMaxPixels);
    boardPixels = math.max(boardPixels, _boardMinPixels);
    if (boardPixels > availableWidth) {
      boardPixels = availableWidth;
    }
    if (boardPixels > maxBoardByHeight) {
      boardPixels = maxBoardByHeight;
    }
    if (boardPixels < _boardMinPixels && maxBoardByHeight < _boardMinPixels) {
      boardPixels = maxBoardByHeight;
    }

    final double usedHeight =
        boardPixels + _boardToRackGap + _rackReservedHeight;
    final double freeHeight = math.max(0, contentHeight - usedHeight);
    final double boardTop = contentTop + (freeHeight * 0.5);

    _boardCellSize = boardPixels / 8;
    _boardOrigin = Vector2((size.x - boardPixels) / 2, boardTop);
    _rackTop = _boardOrigin.y + boardPixels + _boardToRackGap;

    _boardComponent
      ..position = _boardOrigin
      ..size = Vector2.all(boardPixels);
  }

  double _estimateRackReservedHeight() {
    // Keep board scale stable independent of current rack piece shapes.
    final double targetHeight = (_rackCellSize * 3) + 26;
    return targetHeight.clamp(96, 136).toDouble();
  }

  void _rebuildRackPieces(List<Piece> pieces) {
    if (_isShuttingDown) {
      return;
    }
    for (final RackPieceComponent component in _rackComponents) {
      component.removeFromParent();
    }
    _rackComponents.clear();

    final List<Vector2> homePositions = _rackPositionsForPieces(pieces);
    final _BoardPalette palette = _currentPalette;

    for (int i = 0; i < pieces.length; i++) {
      final RackPieceComponent component = RackPieceComponent(
        piece: pieces[i],
        cellSize: _rackCellSize,
        minTouchTargetSize: _rackMinTouchTargetSize,
        dragActivationDistance: _dragActivationDistance,
        touchDragLiftPixels: _touchDragLiftPixels,
        visualPreset: _visualPreset,
        homePosition: homePositions[i],
        baseColor: palette.rackColor,
        dragColor: palette.rackDragColor,
        onDragMoved: onRackPieceDragged,
        onDropped: onRackPieceDropped,
      );
      _rackComponents.add(component);
      add(component);
    }
  }

  void _positionRackPieces() {
    if (_isShuttingDown) {
      return;
    }
    if (!hasLayout) {
      return;
    }
    final List<Piece> pieces =
        _rackComponents.map((RackPieceComponent item) => item.piece).toList();
    final List<Vector2> homePositions = _rackPositionsForPieces(pieces);

    for (int i = 0; i < _rackComponents.length; i++) {
      final RackPieceComponent component = _rackComponents[i];
      component.updateHome(homePositions[i]);
    }
  }

  List<Vector2> _rackPositionsForPieces(List<Piece> pieces) {
    if (pieces.isEmpty) {
      return <Vector2>[];
    }
    if (!hasLayout) {
      double cursorX = _layoutHorizontalPadding;
      final List<Vector2> fallback = <Vector2>[];
      for (final Piece piece in pieces) {
        final Vector2 pieceSize = RackPieceComponent.visualSize(
          piece: piece,
          cellSize: _rackCellSize,
        );
        fallback.add(Vector2(cursorX, _layoutTopInset + 140));
        cursorX += pieceSize.x + 12;
      }
      return fallback;
    }

    final double sumWidths = pieces
        .map(
          (Piece piece) => RackPieceComponent.visualSize(
            piece: piece,
            cellSize: _rackCellSize,
          ).x,
        )
        .fold<double>(0, (double sum, double value) => sum + value);

    double spacing = 16;
    final double maxRackWidth = size.x - (_layoutHorizontalPadding * 2);
    if (pieces.length > 1) {
      final double maxSpacing =
          (maxRackWidth - sumWidths) / (pieces.length - 1).toDouble();
      spacing = maxSpacing.clamp(8, 16);
    }

    final List<Vector2> pieceSizes = pieces
        .map(
          (Piece piece) => RackPieceComponent.visualSize(
            piece: piece,
            cellSize: _rackCellSize,
          ),
        )
        .toList();
    final double maxHeight = pieceSizes
        .map((Vector2 value) => value.y)
        .fold<double>(0, (double prev, double current) {
      return current > prev ? current : prev;
    });

    final double totalWidth = sumWidths + (spacing * (pieceSizes.length - 1));
    final double centeredStartX = (size.x - totalWidth) / 2;
    final double startX = math.max(_layoutHorizontalPadding, centeredStartX);
    final double rackTopPadding =
        ((_rackReservedHeight - maxHeight) / 2).clamp(0, 24).toDouble();
    final double rackTop = _rackTop + rackTopPadding;

    double cursorX = startX;
    final List<Vector2> result = <Vector2>[];
    for (final Vector2 pieceSize in pieceSizes) {
      result.add(
        Vector2(
          cursorX,
          rackTop + ((maxHeight - pieceSize.y) / 2),
        ),
      );
      cursorX += pieceSize.x + spacing;
    }
    return result;
  }

  _BoardAnchor? _anchorForPiecePosition(RackPieceComponent pieceComponent) {
    final Rect boardRect = Rect.fromLTWH(
      _boardOrigin.x,
      _boardOrigin.y,
      _boardCellSize * 8,
      _boardCellSize * 8,
    );
    final Rect pieceRect = Rect.fromLTWH(
      pieceComponent.position.x,
      pieceComponent.position.y,
      pieceComponent.size.x,
      pieceComponent.size.y,
    );
    if (!pieceRect.overlaps(boardRect.inflate(_boardCellSize * 1.2))) {
      return null;
    }

    final int anchorX =
        ((pieceComponent.position.x - _boardOrigin.x) / _boardCellSize).round();
    final int anchorY =
        ((pieceComponent.position.y - _boardOrigin.y) / _boardCellSize).round();
    return _BoardAnchor(anchorX, anchorY);
  }

  void _setPaletteFromState(int index) {
    final int normalized = index % _palettes.length;
    if (normalized != _activePaletteIndex) {
      _previousPaletteIndex = _activePaletteIndex;
      _activePaletteIndex = normalized;
      _paletteTransition = 0;
    }
    _applyCurrentPalette();
  }

  _BoardPalette get _currentPalette {
    final _BoardPalette from = _palettes[_previousPaletteIndex];
    final _BoardPalette to = _palettes[_activePaletteIndex];
    return _BoardPalette.lerp(from, to, _paletteTransition);
  }

  void _applyCurrentPalette() {
    final _BoardPalette palette = _currentPalette;
    _boardComponent.setPalette(
      boardBackgroundColor: palette.boardBackground,
      occupiedColor: palette.occupiedColor,
    );
    _boardComponent.setVisualPreset(_visualPreset);
    for (final RackPieceComponent component in _rackComponents) {
      component.updatePalette(
        baseColor: palette.rackColor,
        dragColor: palette.rackDragColor,
      );
      component.updateVisualPreset(_visualPreset);
    }
  }

  void _playLineClearAnimation({
    required int strength,
    required Set<BoardCell> clearedCells,
  }) {
    add(
      LineClearFlashComponent(
        boardOrigin: _boardOrigin.clone(),
        boardSize: Vector2.all(_boardCellSize * 8),
        strength: strength,
      ),
    );

    final double cellSize = _boardCellSize;
    for (final BoardCell cell in clearedCells) {
      final Vector2 cellCenter = Vector2(
        _boardOrigin.x + (cell.x * cellSize) + (cellSize / 2),
        _boardOrigin.y + (cell.y * cellSize) + (cellSize / 2),
      );
      add(
        CellBurstComponent(
          burstCenter: cellCenter,
          cellSize: cellSize,
          intensity: strength,
        ),
      );
    }
  }

  void _playComboAnimation({
    required int comboStreak,
  }) {
    add(
      ComboPulseComponent(
        text: 'Combo x$comboStreak',
        startPosition: Vector2(
            _boardOrigin.x + (_boardCellSize * 2.4), _boardOrigin.y - 4),
      ),
    );
  }
}

enum BlockVisualPreset {
  soft,
  crystal,
}

BlockVisualPreset _blockVisualPresetFromString(String rawValue) {
  switch (rawValue.trim().toLowerCase()) {
    case 'crystal':
      return BlockVisualPreset.crystal;
    case 'soft':
    default:
      return BlockVisualPreset.soft;
  }
}

Color _mixColor(
  Color from,
  Color to,
  double t,
) {
  return Color.lerp(from, to, t) ?? to;
}

Color _adjustLightness(
  Color color,
  double delta,
) {
  final HSLColor hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness + delta).clamp(0, 1).toDouble())
      .toColor();
}

Color _withAlpha(
  Color color,
  double alpha,
) {
  final int a =
      (alpha.clamp(0, 1).toDouble() * 255).round().clamp(0, 255).toInt();
  final int rgb = _colorToArgb32(color) & 0x00FFFFFF;
  return Color((a << 24) | rgb);
}

int _colorToArgb32(Color color) {
  final dynamic dynamicColor = color;
  try {
    return dynamicColor.toARGB32() as int;
  } catch (_) {
    return dynamicColor.value as int;
  }
}

void _drawGlassBlockCell(
  Canvas canvas, {
  required Rect rect,
  required Color tint,
  required BlockVisualPreset preset,
  double opacity = 1,
  bool intenseGlow = false,
}) {
  final double radius = (rect.width * 0.16).clamp(4, 8).toDouble();
  final RRect rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
  final bool isCrystal = preset == BlockVisualPreset.crystal;

  final Color topTint = _withAlpha(
    _adjustLightness(tint, isCrystal ? 0.28 : 0.24),
    (isCrystal ? 0.54 : 0.66) * opacity,
  );
  final Color bottomTint = _mixColor(
    _adjustLightness(tint, isCrystal ? -0.08 : -0.1),
    const Color(0xFF0D1731),
    isCrystal ? 0.48 : 0.42,
  );
  final Color bottomTintWithAlpha =
      _withAlpha(bottomTint, (isCrystal ? 0.44 : 0.58) * opacity);
  final Color outlineTint = _withAlpha(
      _mixColor(tint, const Color(0xFFF2FAFF), 0.56), 0.95 * opacity);
  final Color prismTop = _mixColor(tint, const Color(0xFF9FE7FF), 0.62);
  final Color prismBottom = _mixColor(tint, const Color(0xFFCBA2FF), 0.56);
  final bool enableOuterGlow = intenseGlow || isCrystal;
  if (enableOuterGlow) {
    final Paint glowPaint = Paint()
      ..color = _withAlpha(
        tint,
        (intenseGlow ? (isCrystal ? 0.6 : 0.5) : (isCrystal ? 0.4 : 0.3)) *
            opacity,
      );
    if (intenseGlow || isCrystal) {
      glowPaint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        intenseGlow ? (isCrystal ? 7.2 : 6.0) : 4.2,
      );
    }
    canvas.drawRRect(rr.inflate(intenseGlow ? 0.75 : 0.35), glowPaint);
  }

  final Paint bodyPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        topTint,
        bottomTintWithAlpha,
      ],
    ).createShader(rect);
  canvas.drawRRect(rr, bodyPaint);

  final Paint prismPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        _withAlpha(prismTop, (isCrystal ? 0.26 : 0.2) * opacity),
        _withAlpha(Colors.white, (isCrystal ? 0.14 : 0.08) * opacity),
        _withAlpha(prismBottom, (isCrystal ? 0.28 : 0.22) * opacity),
      ],
      stops: const <double>[0, 0.45, 1],
    ).createShader(rect);
  canvas.drawRRect(rr, prismPaint);

  final Paint coreGlowPaint = Paint()
    ..shader = RadialGradient(
      center: const Alignment(0, 0),
      radius: 0.72,
      colors: <Color>[
        _withAlpha(
          Colors.white,
          (intenseGlow
                  ? (isCrystal ? 0.62 : 0.46)
                  : (isCrystal ? 0.48 : 0.34)) *
              opacity,
        ),
        _withAlpha(
          tint,
          (intenseGlow
                  ? (isCrystal ? 0.48 : 0.36)
                  : (isCrystal ? 0.36 : 0.26)) *
              opacity,
        ),
        Colors.transparent,
      ],
      stops: const <double>[0, 0.35, 1],
    ).createShader(rect);
  canvas.drawRRect(rr, coreGlowPaint);

  final Paint sheenPaint = Paint()
    ..shader = RadialGradient(
      center: const Alignment(-0.25, -0.35),
      radius: 1.1,
      colors: <Color>[
        _withAlpha(Colors.white, (isCrystal ? 0.56 : 0.44) * opacity),
        _withAlpha(Colors.white, (isCrystal ? 0.18 : 0.12) * opacity),
        Colors.transparent,
      ],
      stops: const <double>[0, 0.56, 1],
    ).createShader(rect);
  canvas.drawRRect(rr, sheenPaint);

  final Paint edgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.35
    ..color = outlineTint;
  canvas.drawRRect(rr, edgePaint);

  final Paint innerEdgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9
    ..color = _withAlpha(Colors.white, 0.22 * opacity);
  canvas.drawRRect(rr.deflate(0.9), innerEdgePaint);

  final Paint cornerSparkPaint = Paint()
    ..color = _withAlpha(
      Colors.white,
      (isCrystal ? (intenseGlow ? 0.58 : 0.34) : 0.42) * opacity,
    );
  if (intenseGlow || isCrystal) {
    cornerSparkPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.1);
  }
  final double spark = rect.width * 0.07;
  canvas.drawCircle(
    Offset(rect.left + (rect.width * 0.18), rect.top + (rect.height * 0.2)),
    spark,
    cornerSparkPaint,
  );
}

class BoardComponent extends PositionComponent {
  static const List<Offset> _starMap = <Offset>[
    Offset(0.1, 0.14),
    Offset(0.22, 0.08),
    Offset(0.36, 0.2),
    Offset(0.54, 0.12),
    Offset(0.68, 0.23),
    Offset(0.84, 0.18),
    Offset(0.18, 0.34),
    Offset(0.41, 0.39),
    Offset(0.61, 0.31),
    Offset(0.79, 0.44),
    Offset(0.14, 0.56),
    Offset(0.33, 0.6),
    Offset(0.56, 0.52),
    Offset(0.74, 0.67),
    Offset(0.23, 0.76),
    Offset(0.5, 0.82),
    Offset(0.83, 0.78),
  ];

  BoardState _boardState = BoardState.empty(size: 8);
  _PreviewState? _previewState;
  _HintState? _hintState;
  Color _boardBackgroundColor = const Color(0xFF0C1B36);
  Color _occupiedColor = const Color(0xFF55CEFF);
  BlockVisualPreset _visualPreset = BlockVisualPreset.soft;

  void setBoardState(BoardState boardState) {
    _boardState = boardState;
  }

  void setPreview({
    required Piece piece,
    required int anchorX,
    required int anchorY,
    required bool valid,
  }) {
    _previewState = _PreviewState(
      piece: piece,
      anchorX: anchorX,
      anchorY: anchorY,
      valid: valid,
    );
  }

  void clearPreview() {
    _previewState = null;
  }

  void setHint({
    required Piece piece,
    required int anchorX,
    required int anchorY,
  }) {
    _hintState = _HintState(
      piece: piece,
      anchorX: anchorX,
      anchorY: anchorY,
    );
  }

  void clearHint() {
    _hintState = null;
  }

  void setPalette({
    required Color boardBackgroundColor,
    required Color occupiedColor,
  }) {
    _boardBackgroundColor = boardBackgroundColor;
    _occupiedColor = occupiedColor;
  }

  void setVisualPreset(BlockVisualPreset preset) {
    _visualPreset = preset;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final double cellSize = size.x / _boardState.size;
    final Rect boardRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final RRect boardRRect = RRect.fromRectAndRadius(
      boardRect,
      const Radius.circular(14),
    );
    final Color boardTop =
        _mixColor(_boardBackgroundColor, const Color(0xFF3653A2), 0.3);
    final Color boardBottom =
        _mixColor(_boardBackgroundColor, const Color(0xFF050A1A), 0.42);

    final Paint boardBackground = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[boardTop, boardBottom],
      ).createShader(boardRect);
    final Paint boardGlow = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.25),
        radius: 1.08,
        colors: <Color>[
          Color(0x2B6FC6FF),
          Colors.transparent,
        ],
      ).createShader(boardRect);
    final Paint boardPrismGlow = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.38, 0.25),
        radius: 1.12,
        colors: <Color>[
          Color(0x238F6FFF),
          Colors.transparent,
        ],
      ).createShader(boardRect);
    final Paint boardOuterGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0x338DD4FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.6);
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = const Color(0x7390CDFF);
    final Paint minorGridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x245CA8DD);
    final Paint majorGridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = const Color(0x3C7FC5F4);
    final Paint starCorePaint = Paint()..color = const Color(0x55B7ECFF);
    final Paint starAuraPaint = Paint()
      ..color = const Color(0x22A2DEFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8);

    canvas.drawRRect(boardRRect, boardBackground);
    canvas.drawRRect(boardRRect, boardGlow);
    canvas.drawRRect(boardRRect, boardPrismGlow);

    canvas.save();
    canvas.clipRRect(boardRRect);
    for (final Offset uv in _starMap) {
      final Offset point = Offset(size.x * uv.dx, size.y * uv.dy);
      canvas.drawCircle(point, cellSize * 0.035, starAuraPaint);
      canvas.drawCircle(point, cellSize * 0.014, starCorePaint);
    }
    for (int i = 0; i <= _boardState.size; i++) {
      final double lineOffset = i * cellSize;
      final Paint paint = (i % 2 == 0) ? majorGridPaint : minorGridPaint;
      canvas.drawLine(
        Offset(lineOffset, 0),
        Offset(lineOffset, size.y),
        paint,
      );
      canvas.drawLine(
        Offset(0, lineOffset),
        Offset(size.x, lineOffset),
        paint,
      );
    }
    canvas.restore();
    canvas.drawRRect(boardRRect.inflate(0.4), boardOuterGlow);
    canvas.drawRRect(boardRRect, borderPaint);

    for (final BoardCell cell in _boardState.occupiedCells) {
      final Rect occupiedRect = Rect.fromLTWH(
        cell.x * cellSize + 2,
        cell.y * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      );
      _drawGlassBlockCell(
        canvas,
        rect: occupiedRect,
        tint: _occupiedColor,
        preset: _visualPreset,
        opacity: 1,
        intenseGlow: true,
      );
    }

    final _HintState? hint = _hintState;
    if (hint != null) {
      for (final PieceCellOffset offset in hint.piece.cells) {
        final int x = hint.anchorX + offset.dx;
        final int y = hint.anchorY + offset.dy;
        if (x < 0 || y < 0 || x >= _boardState.size || y >= _boardState.size) {
          continue;
        }
        final Rect hintRect = Rect.fromLTWH(
          x * cellSize + 4,
          y * cellSize + 4,
          cellSize - 8,
          cellSize - 8,
        );
        _drawGlassBlockCell(
          canvas,
          rect: hintRect,
          tint: const Color(0xFF7EC8FF),
          preset: _visualPreset,
          opacity: 0.42,
        );
      }
    }

    final _PreviewState? preview = _previewState;
    if (preview != null) {
      final Color previewTint =
          preview.valid ? const Color(0xFF7EC8FF) : const Color(0xFFFF6B7E);
      for (final PieceCellOffset offset in preview.piece.cells) {
        final int x = preview.anchorX + offset.dx;
        final int y = preview.anchorY + offset.dy;
        if (x < 0 || y < 0 || x >= _boardState.size || y >= _boardState.size) {
          continue;
        }

        final Rect previewRect = Rect.fromLTWH(
          x * cellSize + 3,
          y * cellSize + 3,
          cellSize - 6,
          cellSize - 6,
        );
        _drawGlassBlockCell(
          canvas,
          rect: previewRect,
          tint: previewTint,
          preset: _visualPreset,
          opacity: preview.valid ? 0.58 : 0.54,
          intenseGlow: preview.valid,
        );
      }
    }
  }
}

class RackPieceComponent extends PositionComponent with DragCallbacks {
  RackPieceComponent({
    required this.piece,
    required this.cellSize,
    required this.minTouchTargetSize,
    required this.dragActivationDistance,
    required this.touchDragLiftPixels,
    required BlockVisualPreset visualPreset,
    required Vector2 homePosition,
    required Color baseColor,
    required Color dragColor,
    required this.onDragMoved,
    required this.onDropped,
  })  : _homePosition = homePosition.clone(),
        _baseColor = baseColor,
        _dragColor = dragColor,
        _visualPreset = visualPreset {
    size = visualSize(
      piece: piece,
      cellSize: cellSize,
    );
    position = _homePosition.clone();
  }

  final Piece piece;
  final double cellSize;
  final double minTouchTargetSize;
  final double dragActivationDistance;
  final double touchDragLiftPixels;
  final void Function(RackPieceComponent component) onDragMoved;
  final Future<void> Function(RackPieceComponent component) onDropped;
  Vector2 _homePosition;
  Color _baseColor;
  Color _dragColor;
  BlockVisualPreset _visualPreset;
  bool _dragging = false;
  bool _dragPending = false;
  final Vector2 _pendingDelta = Vector2.zero();
  double _pendingDistance = 0;
  double _dragLiftPixels = 0;
  double _dragVisualProgress = 0;

  static Vector2 visualSize({
    required Piece piece,
    required double cellSize,
  }) {
    int maxDx = 0;
    int maxDy = 0;
    for (final PieceCellOffset cell in piece.cells) {
      if (cell.dx > maxDx) {
        maxDx = cell.dx;
      }
      if (cell.dy > maxDy) {
        maxDy = cell.dy;
      }
    }

    return Vector2((maxDx + 1) * cellSize, (maxDy + 1) * cellSize);
  }

  void updateHome(Vector2 newHome) {
    _homePosition = newHome.clone();
    if (!_dragging) {
      position = _homePosition.clone();
    }
  }

  void resetToHome() {
    position = _homePosition.clone();
    _clearDragState();
  }

  void updatePalette({
    required Color baseColor,
    required Color dragColor,
  }) {
    _baseColor = baseColor;
    _dragColor = dragColor;
  }

  void updateVisualPreset(BlockVisualPreset preset) {
    _visualPreset = preset;
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    final double targetWidth = math.max(size.x, minTouchTargetSize);
    final double targetHeight = math.max(size.y, minTouchTargetSize);
    final double left = (size.x - targetWidth) / 2;
    final double top = (size.y - targetHeight) / 2;
    final Rect hitRect = Rect.fromLTWH(left, top, targetWidth, targetHeight);
    return hitRect.contains(Offset(point.x, point.y));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final Color tint = _dragging ? _dragColor : _baseColor;
    final double scale = lerpDouble(1, 1.035, _dragVisualProgress) ?? 1;
    if ((scale - 1).abs() > 0.0001) {
      canvas.save();
      final double cx = size.x * 0.5;
      final double cy = size.y * 0.5;
      canvas.translate(cx, cy);
      canvas.scale(scale, scale);
      canvas.translate(-cx, -cy);
    }

    for (final PieceCellOffset cell in piece.cells) {
      final Rect rect = Rect.fromLTWH(
        (cell.dx * cellSize) + 2,
        (cell.dy * cellSize) + 2,
        cellSize - 4,
        cellSize - 4,
      );
      _drawGlassBlockCell(
        canvas,
        rect: rect,
        tint: tint,
        preset: _visualPreset,
        opacity: 1,
        intenseGlow: true,
      );
    }
    if ((scale - 1).abs() > 0.0001) {
      canvas.restore();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final double targetVisual = _dragging ? 1 : 0;
    if ((_dragVisualProgress - targetVisual).abs() > 0.001) {
      final double step = dt * 10;
      _dragVisualProgress = _dragVisualProgress < targetVisual
          ? (_dragVisualProgress + step).clamp(0, targetVisual).toDouble()
          : (_dragVisualProgress - step).clamp(targetVisual, 1).toDouble();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    _dragPending = true;
    _pendingDistance = 0;
    _pendingDelta.setZero();
    _dragLiftPixels = 0;
    final PointerDeviceKind kind = event.deviceKind;
    final bool isTouchLike = kind != PointerDeviceKind.mouse;
    if (isTouchLike) {
      _dragLiftPixels = touchDragLiftPixels;
      // Keep the dragged piece above finger from the very first touch frame.
      position.y -= _dragLiftPixels;
    }
    onDragMoved(this);
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_dragging && _dragPending) {
      _pendingDelta.add(event.localDelta);
      _pendingDistance += event.localDelta.length;
      if (_pendingDistance < dragActivationDistance) {
        super.onDragUpdate(event);
        return;
      }
      _dragging = true;
      _dragPending = false;
      priority = 100;
      position += _pendingDelta;
      _pendingDelta.setZero();
      onDragMoved(this);
      super.onDragUpdate(event);
      return;
    }
    if (!_dragging) {
      super.onDragUpdate(event);
      return;
    }
    position += event.localDelta;
    onDragMoved(this);
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!_dragging) {
      resetToHome();
      onDragMoved(this);
      super.onDragEnd(event);
      return;
    }
    _clearDragState();
    unawaited(onDropped(this));
    super.onDragEnd(event);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    resetToHome();
    onDragMoved(this);
    super.onDragCancel(event);
  }

  void _clearDragState() {
    _dragging = false;
    _dragPending = false;
    _pendingDistance = 0;
    _pendingDelta.setZero();
    _dragLiftPixels = 0;
    priority = 0;
  }
}

class _BoardAnchor {
  const _BoardAnchor(this.x, this.y);

  final int x;
  final int y;
}

class _PreviewState {
  const _PreviewState({
    required this.piece,
    required this.anchorX,
    required this.anchorY,
    required this.valid,
  });

  final Piece piece;
  final int anchorX;
  final int anchorY;
  final bool valid;
}

class _HintState {
  const _HintState({
    required this.piece,
    required this.anchorX,
    required this.anchorY,
  });

  final Piece piece;
  final int anchorX;
  final int anchorY;
}

class _BoardPalette {
  const _BoardPalette({
    required this.boardBackground,
    required this.occupiedColor,
    required this.rackColor,
    required this.rackDragColor,
  });

  final Color boardBackground;
  final Color occupiedColor;
  final Color rackColor;
  final Color rackDragColor;

  factory _BoardPalette.lerp(
    _BoardPalette a,
    _BoardPalette b,
    double t,
  ) {
    return _BoardPalette(
      boardBackground: Color.lerp(a.boardBackground, b.boardBackground, t) ??
          b.boardBackground,
      occupiedColor:
          Color.lerp(a.occupiedColor, b.occupiedColor, t) ?? b.occupiedColor,
      rackColor: Color.lerp(a.rackColor, b.rackColor, t) ?? b.rackColor,
      rackDragColor:
          Color.lerp(a.rackDragColor, b.rackDragColor, t) ?? b.rackDragColor,
    );
  }
}

class LineClearFlashComponent extends PositionComponent {
  LineClearFlashComponent({
    required this.boardOrigin,
    required this.boardSize,
    required this.strength,
  }) {
    priority = 200;
  }

  final Vector2 boardOrigin;
  final Vector2 boardSize;
  final int strength;
  static const double _duration = 0.32;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double t = (_elapsed / _duration).clamp(0, 1);
    final double alpha = (1 - t) * (0.22 + (strength * 0.07));
    final Paint paint = Paint()
      ..color = Color.fromRGBO(34, 179, 126, alpha.clamp(0, 0.55));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          boardOrigin.x,
          boardOrigin.y,
          boardSize.x,
          boardSize.y,
        ),
        const Radius.circular(14),
      ),
      paint,
    );
  }
}

class ComboPulseComponent extends PositionComponent {
  ComboPulseComponent({
    required this.text,
    required this.startPosition,
  }) {
    priority = 210;
  }

  final String text;
  final Vector2 startPosition;
  static const double _duration = 0.75;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double t = (_elapsed / _duration).clamp(0, 1);
    final double opacity = (1 - t).clamp(0, 1);
    final double yOffset = t * 26;
    final TextPaint textPaint = TextPaint(
      style: TextStyle(
        fontSize: 24 - (t * 4),
        fontWeight: FontWeight.w800,
        color: Color.fromRGBO(255, 138, 76, opacity),
      ),
    );
    textPaint.render(
      canvas,
      text,
      Vector2(startPosition.x, startPosition.y - yOffset),
    );
  }
}

class CellBurstComponent extends PositionComponent {
  CellBurstComponent({
    required this.burstCenter,
    required this.cellSize,
    required this.intensity,
  }) {
    priority = 205;
  }

  final Vector2 burstCenter;
  final double cellSize;
  final int intensity;
  static const double _duration = 0.30;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double t = (_elapsed / _duration).clamp(0, 1);
    final double alpha = (1 - t).clamp(0, 1);
    final double maxRadius = (cellSize * 0.52) + (intensity * 1.5);
    final double radius = maxRadius * (0.35 + (0.65 * t));

    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 + (intensity * 0.3)
      ..color = Color.fromRGBO(255, 214, 102, 0.9 * alpha);

    final Paint corePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Color.fromRGBO(255, 166, 43, 0.35 * alpha);

    canvas.drawCircle(
      Offset(burstCenter.x, burstCenter.y),
      radius * 0.48,
      corePaint,
    );
    canvas.drawCircle(
      Offset(burstCenter.x, burstCenter.y),
      radius,
      ringPaint,
    );
  }
}
