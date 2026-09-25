import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/device/haptics_controller.dart';
import '../../../domain/gameplay/board_state.dart';
import '../../../domain/gameplay/move.dart';
import '../../../domain/gameplay/piece.dart';
import '../../../l10n/verbal_tiers.dart';
import '../../../ui/effects/burst_field.dart';
import '../../../ui/effects/glass_board.dart';
import '../../../ui/effects/line_clear_flash_component.dart';
import '../../../ui/effects/score_pop_component.dart';
import '../../../ui/effects/shockwave_ring_component.dart';
import '../../../ui/effects/vfx_director.dart';
import '../../../ui/effects/vfx_events.dart';
import '../../diagnostics/diagnostics_screen.dart';
import '../../diagnostics/step1j_decomposition.dart';
import '../../diagnostics/step6_benchmark.dart';
import '../audio/game_sfx_player.dart';
import '../application/game_loop_controller.dart';
import '../application/game_loop_view_state.dart';
import '../application/models/models.dart';

export '../../../ui/effects/camera_shake_effect.dart';
export '../../../ui/effects/combo_pulse_component.dart';
export '../../../ui/effects/landing_squash_component.dart';
export '../../../ui/effects/line_clear_flash_component.dart';
export '../../../ui/effects/piece_aura_shader.dart';
export '../../../ui/effects/score_pop_component.dart';
export '../../../ui/effects/shockwave_ring_component.dart';
export '../../../ui/effects/vfx_director.dart';
export '../../../ui/effects/vfx_events.dart';

class BlockPuzzleGame extends FlameGame {
  static const double _touchDragLiftPixels = 50;
  static double get touchDragLiftPixels => _touchDragLiftPixels;

  BlockPuzzleGame({
    required this.controller,
    required this.sfxPlayer,
    required this.haptics,
    this.isDailyChallenge = false,
  });

  final GameLoopController controller;
  final GameSfxPlayer sfxPlayer;
  final HapticsController haptics;
  final bool isDailyChallenge;

  final BoardComponent _boardComponent = BoardComponent();
  final BurstField _burst = BurstField();
  late final VfxDirector _vfxDirector = VfxDirector(
    burstField: _burst,
    viewfinder: camera.viewfinder,
    isReducedMotion: () => Step6Benchmark.reducedMotion.value,
    onScreenShake: (double amplitude) => _playScreenShake(amplitude: amplitude),
  );
  VfxDirector get vfxDirector => _vfxDirector;
  final List<RackPieceComponent> _rackComponents = <RackPieceComponent>[];
  void Function()? _stateListener;
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

  static const _BoardPalette _neonPalette = _BoardPalette(
    boardBackground: Color(0xFF070B14),
    occupiedColor: Color(0xFF00E5FF),
    rackColor: Color(0xFF00B0FF),
    rackDragColor: Color(0xFF80D8FF),
  );

  static const _BoardPalette _monoPalette = _BoardPalette(
    boardBackground: Color(0xFF16181D),
    occupiedColor: Color(0xFFE8ECEF),
    rackColor: Color(0xFFCFD8DC),
    rackDragColor: Color(0xFFFFFFFF),
  );

  static const List<_BoardPalette> _palettes = <_BoardPalette>[
    _BoardPalette(
      boardBackground: Color(0xFF0C1B37),
      occupiedColor: Color(0xFF92E4FF),
      rackColor: Color(0xFF88DBFF),
      rackDragColor: Color(0xFFC6F1FF),
    ),
    _BoardPalette(
      boardBackground: Color(0xFF0E1E3D),
      occupiedColor: Color(0xFFB8A8FF),
      rackColor: Color(0xFFAB9BFF),
      rackDragColor: Color(0xFFDAD2FF),
    ),
    _BoardPalette(
      boardBackground: Color(0xFF0D213F),
      occupiedColor: Color(0xFF9FE2FF),
      rackColor: Color(0xFF95D8FF),
      rackDragColor: Color(0xFFCFF2FF),
    ),
    _BoardPalette(
      boardBackground: Color(0xFF0E1E3A),
      occupiedColor: Color(0xFFA8DEFF),
      rackColor: Color(0xFF9DD5FF),
      rackDragColor: Color(0xFFD2EFFF),
    ),
    _BoardPalette(
      boardBackground: Color(0xFF122041),
      occupiedColor: Color(0xFFBEAEFF),
      rackColor: Color(0xFFB09DFF),
      rackDragColor: Color(0xFFDDD4FF),
    ),
    _BoardPalette(
      boardBackground: Color(0xFF0C1D3A),
      occupiedColor: Color(0xFF98E0FF),
      rackColor: Color(0xFF8FD4FF),
      rackDragColor: Color(0xFFC9F0FF),
    ),
  ];

  @override
  Color backgroundColor() => const Color(0x00000000);

  int _activePaletteIndex = 0;
  int _previousPaletteIndex = 0;
  double _paletteTransition = 1;

  @override
  Future<void> onLoad() async {
    await sfxPlayer.preload();
    await controller.initialize(isDailyChallenge: isDailyChallenge);

    if (_isShuttingDown) {
      return;
    }

    add(_boardComponent);
    add(_vfxDirector);
    if (kDiagnosticsEnabled) {
      add(_Step6BenchRunnerComponent(this));
    }

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
      unawaited(haptics.heavyImpact());
      return;
    }

    _dropInProgress = true;
    final int prevScore = controller.state.scoreState.totalScore;
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
      unawaited(haptics.heavyImpact());
      return;
    }

    unawaited(sfxPlayer.playPiecePlaced());
    unawaited(haptics.mediumImpact());

    final List<Vector2> cellCenters = <Vector2>[];
    final List<Rect> cellRects = <Rect>[];
    for (final PieceCellOffset offset in pieceComponent.piece.cells) {
      final double cellLeft = _boardOrigin.x + ((anchor.x + offset.dx) * _boardCellSize);
      final double cellTop = _boardOrigin.y + ((anchor.y + offset.dy) * _boardCellSize);
      cellCenters.add(
        Vector2(
          cellLeft + (_boardCellSize / 2),
          cellTop + (_boardCellSize / 2),
        ),
      );
      cellRects.add(
        Rect.fromLTWH(cellLeft, cellTop, _boardCellSize, _boardCellSize),
      );
    }
    _vfxDirector.handleEvent(
      VfxEvent.piecePlaced(
        position: Vector2(
          _boardOrigin.x + (anchor.x * _boardCellSize),
          _boardOrigin.y + (anchor.y * _boardCellSize),
        ),
        cellCenters: cellCenters,
        cellRects: cellRects,
        cellSize: _boardCellSize,
        color: _currentPalette.occupiedColor,
      ),
    );

    if (result.clearedLines > 0) {
      unawaited(sfxPlayer.playLineClear(clearedLines: result.clearedLines));
      if (result.comboStreak >= 6) {
        unawaited(haptics.heavyImpact());
      } else if (result.comboStreak >= 3) {
        unawaited(haptics.mediumImpact());
      } else {
        unawaited(haptics.lightImpact());
      }
      _playLineClearAnimation(
        strength: result.clearedLines,
        clearedCells: result.clearedCells,
      );
      _playShockwave(result.clearedCells);
      final int scoreDelta = controller.state.scoreState.totalScore - prevScore;
      if (scoreDelta > 0) {
        _playScorePop(scoreDelta, result.clearedCells);
      }
    }

    if (result.isAllClear) {
      unawaited(haptics.doubleHeavyImpact());
      _playPerfectClear();
    }

    if (result.comboStreak > 1) {
      unawaited(sfxPlayer.playCombo(comboStreak: result.comboStreak));
      _playComboAnimation(comboStreak: result.comboStreak);
      if (result.comboStreak >= 4) {
        _vfxDirector.triggerHitStop(0.045);
      }
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
        haptics: haptics,
        vfxDirector: vfxDirector,
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
    final String theme = controller.selectedTheme;
    if (theme == 'neon') {
      return _neonPalette;
    } else if (theme == 'mono' || theme == 'monochrome') {
      return _monoPalette;
    }
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

  void _playScreenShake({double amplitude = 2.0}) {
    if (Step6Benchmark.reducedMotion.value) {
      return;
    }
    final double s = amplitude.clamp(2.0, 4.0);
    camera.viewfinder.add(
      SequenceEffect(<Effect>[
        MoveEffect.by(Vector2(s, -s * 0.5), EffectController(duration: 0.02)),
        MoveEffect.by(Vector2(-s * 1.6, s), EffectController(duration: 0.02)),
        MoveEffect.by(Vector2(s * 0.8, -s * 0.7), EffectController(duration: 0.02)),
        MoveEffect.by(Vector2(-s * 0.2, s * 0.2), EffectController(duration: 0.02)),
      ]),
    );
  }

  void _playLineClearAnimation({
    required int strength,
    required Set<BoardCell> clearedCells,
  }) {
    final Vector2 centroid = computeClearedCentroid(
      cells: clearedCells,
      boardOrigin: _boardOrigin,
      cellSize: _boardCellSize,
    );
    _vfxDirector.handleEvent(
      VfxEvent.lineCleared(
        cells: clearedCells,
        centroid: centroid,
        strength: strength,
        color: _currentPalette.occupiedColor,
        boardOrigin: _boardOrigin.clone(),
        cellSize: _boardCellSize,
      ),
    );
  }

  void _playComboAnimation({
    required int comboStreak,
  }) {
    final String tier = VerbalTiers.resolve(comboStreak: comboStreak);
    final String text = tier.isNotEmpty ? '$tier\nCombo x$comboStreak' : 'Combo x$comboStreak';
    _vfxDirector.handleEvent(
      VfxEvent.comboPulse(
        text: text,
        position: Vector2(
          _boardOrigin.x + (_boardCellSize * 4),
          _boardOrigin.y - 12,
        ),
        comboStreak: comboStreak,
      ),
    );
  }

  void _playScorePop(int delta, Set<BoardCell> cells) {
    if (cells.isEmpty) {
      return;
    }
    final Vector2 centroid = computeClearedCentroid(
      cells: cells,
      boardOrigin: _boardOrigin,
      cellSize: _boardCellSize,
    );
    _vfxDirector.handleEvent(
      VfxEvent.scorePopped(
        text: '+$delta',
        position: centroid,
      ),
    );
  }

  void _playShockwave(Set<BoardCell> cells) {
    if (cells.isEmpty) {
      return;
    }
    final Vector2 centroid = computeClearedCentroid(
      cells: cells,
      boardOrigin: _boardOrigin,
      cellSize: _boardCellSize,
    );
    _vfxDirector.handleEvent(
      VfxEvent.shockwave(
        center: centroid,
        boardRect: Rect.fromLTWH(
          _boardOrigin.x,
          _boardOrigin.y,
          _boardCellSize * 8,
          _boardCellSize * 8,
        ),
        color: _currentPalette.occupiedColor,
      ),
    );
  }

  /// Drops the board's cached GPU surfaces so the next frame rebuilds them.
  ///
  /// Called when the app returns to the foreground: the render surface may
  /// have been torn down while it was away, and a `toImageSync` image lives on
  /// the GPU. Drawing one that did not survive is a native crash, which no
  /// error handler in this app can catch, so the cache is rebuilt instead.
  void dropCachedSurfaces() {
    _boardComponent.dropCachedSurfaces();
    for (final RackPieceComponent component in _rackComponents) {
      component.dropCachedSurfaces();
    }
  }

  void triggerStep6BenchEvent(int index) {
    if (!kDiagnosticsEnabled || !Step6Benchmark.effectsEnabled.value) {
      return;
    }
    final bool isReducedMotion = Step6Benchmark.reducedMotion.value;
    final bool isTriple =
        Step6Benchmark.scenario.value == Step6BenchmarkScenario.tripleClear;

    final Rect boardRect = Rect.fromLTWH(
      _boardOrigin.x,
      _boardOrigin.y,
      _boardCellSize * 8,
      _boardCellSize * 8,
    );
    final double cellSize = _boardCellSize;
    final Color burstColor = _currentPalette.occupiedColor;

    if (isTriple) {
      final Set<BoardCell> cells = Step6Benchmark.tripleClear24Cells;
      final Vector2 centroid = computeClearedCentroid(
        cells: cells,
        boardOrigin: _boardOrigin,
        cellSize: cellSize,
      );

      add(
        ShockwaveRingComponent(
          center: centroid,
          boardRect: boardRect,
          color: burstColor,
        ),
      );

      for (final BoardCell cell in cells) {
        _burst.spawnBurst(
          x: _boardOrigin.x + (cell.x * cellSize) + (cellSize / 2),
          y: _boardOrigin.y + (cell.y * cellSize) + (cellSize / 2),
          color: burstColor,
          count: 3,
          sizeBase: cellSize * 0.12,
          sizeJitter: cellSize * 0.1,
        );
      }

      if (!isReducedMotion) {
        add(
          LineClearFlashComponent(
            boardOrigin: _boardOrigin.clone(),
            boardSize: Vector2.all(_boardCellSize * 8),
            strength: 3,
          ),
        );
      }

      add(
        ScorePopComponent(
          text: '+300',
          startPosition: centroid,
        ),
      );
    } else {
      final BoardCell cell =
          Step6Benchmark.benchCentroids[index % Step6Benchmark.benchCentroids.length];
      final double cx = _boardOrigin.x + (cell.x + 0.5) * _boardCellSize;
      final double cy = _boardOrigin.y + (cell.y + 0.5) * _boardCellSize;

      add(
        ShockwaveRingComponent(
          center: Vector2(cx, cy),
          boardRect: boardRect,
          color: burstColor,
        ),
      );
      _burst.spawnBurst(
        x: cx,
        y: cy,
        color: burstColor,
        count: 3,
        sizeBase: cellSize * 0.12,
        sizeJitter: cellSize * 0.1,
      );
      add(
        ScorePopComponent(
          text: '+${(index + 1) * 10}',
          startPosition: Vector2(cx, cy),
        ),
      );
    }
  }

  void _playPerfectClear() {
    unawaited(sfxPlayer.playCombo(comboStreak: 6));
    unawaited(haptics.doubleHeavyImpact());
    _vfxDirector.handleEvent(
      VfxEvent.allClear(
        boardOrigin: _boardOrigin.clone(),
        boardSize: Vector2.all(_boardCellSize * 8),
        color: const Color(0xFFFFD700),
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
    // ignore: avoid_dynamic_calls
    return dynamicColor.toARGB32() as int;
  } catch (_) {
    // ignore: avoid_dynamic_calls
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
  final double glowBoost = intenseGlow ? 1.28 : 1.0;
  final Color cyanMix = _mixColor(tint, const Color(0xFFA8EEFF), 0.44);
  final Color violetMix = _mixColor(tint, const Color(0xFFCAA9FF), 0.34);

  final Color topTint = _withAlpha(
    _adjustLightness(cyanMix, isCrystal ? 0.34 : 0.3),
    (isCrystal ? 0.44 : 0.48) * opacity,
  );
  final Color bottomTint = _withAlpha(
    _mixColor(
      _adjustLightness(violetMix, isCrystal ? -0.01 : -0.06),
      const Color(0xFF1A2450),
      isCrystal ? 0.24 : 0.3,
    ),
    (isCrystal ? 0.28 : 0.32) * opacity,
  );
  final Color outlineTint = _withAlpha(
    _mixColor(cyanMix, const Color(0xFFF8FDFF), 0.66),
    0.94 * opacity,
  );
  final Color prismTop = _mixColor(cyanMix, const Color(0xFFD7F4FF), 0.62);
  final Color prismBottom = _mixColor(violetMix, const Color(0xFFE0BBFF), 0.4);

  final Paint outerGlowPaint = Paint()
    ..color = _withAlpha(
      cyanMix,
      (isCrystal ? 0.5 : 0.4) * opacity * glowBoost,
    )
    ..maskFilter = MaskFilter.blur(
      BlurStyle.normal,
      isCrystal ? 7.6 : 6.2,
    );
  canvas.drawRRect(rr.inflate(isCrystal ? 0.95 : 0.7), outerGlowPaint);

  final Paint bodyPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        topTint,
        bottomTint,
      ],
    ).createShader(rect);
  canvas.drawRRect(rr, bodyPaint);

  final Paint prismPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        _withAlpha(prismTop, (isCrystal ? 0.35 : 0.27) * opacity),
        _withAlpha(Colors.white, (isCrystal ? 0.18 : 0.14) * opacity),
        _withAlpha(prismBottom, (isCrystal ? 0.34 : 0.25) * opacity),
      ],
      stops: const <double>[0, 0.45, 1],
    ).createShader(rect);
  canvas.drawRRect(rr, prismPaint);

  final Paint prismTiltPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: <Color>[
        _withAlpha(violetMix, (isCrystal ? 0.24 : 0.18) * opacity),
        Colors.transparent,
        _withAlpha(cyanMix, (isCrystal ? 0.24 : 0.18) * opacity),
      ],
      stops: const <double>[0, 0.52, 1],
    ).createShader(rect);
  canvas.drawRRect(rr, prismTiltPaint);

  final Paint coreGlowPaint = Paint()
    ..shader = RadialGradient(
      center: const Alignment(0, 0),
      radius: 0.72,
      colors: <Color>[
        _withAlpha(
          Colors.white,
          (intenseGlow ? (isCrystal ? 0.58 : 0.5) : (isCrystal ? 0.46 : 0.34)) *
              opacity,
        ),
        _withAlpha(
          cyanMix,
          (intenseGlow
                  ? (isCrystal ? 0.46 : 0.37)
                  : (isCrystal ? 0.38 : 0.29)) *
              opacity,
        ),
        _withAlpha(
          violetMix,
          (isCrystal ? 0.23 : 0.17) * opacity,
        ),
        Colors.transparent,
      ],
      stops: const <double>[0, 0.34, 0.64, 1],
    ).createShader(rect);
  canvas.drawRRect(rr, coreGlowPaint);

  final Paint sheenPaint = Paint()
    ..shader = RadialGradient(
      center: const Alignment(-0.25, -0.35),
      radius: 1.1,
      colors: <Color>[
        _withAlpha(Colors.white, (isCrystal ? 0.46 : 0.38) * opacity),
        _withAlpha(Colors.white, (isCrystal ? 0.18 : 0.12) * opacity),
        Colors.transparent,
      ],
      stops: const <double>[0, 0.56, 1],
    ).createShader(rect);
  canvas.drawRRect(rr, sheenPaint);

  final Paint edgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.22
    ..color = outlineTint;
  canvas.drawRRect(rr, edgePaint);

  final Paint innerEdgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.78
    ..color = _withAlpha(Colors.white, 0.26 * opacity);
  canvas.drawRRect(rr.deflate(0.9), innerEdgePaint);

  final Paint facetPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.78
    ..color = _withAlpha(Colors.white, 0.23 * opacity);
  final Offset center = rect.center;
  canvas.drawLine(
    Offset(rect.left + (rect.width * 0.22), center.dy),
    Offset(center.dx, rect.top + (rect.height * 0.2)),
    facetPaint,
  );
  canvas.drawLine(
    Offset(center.dx, rect.top + (rect.height * 0.2)),
    Offset(rect.right - (rect.width * 0.22), center.dy),
    facetPaint,
  );
  canvas.drawLine(
    Offset(rect.left + (rect.width * 0.22), center.dy),
    Offset(center.dx, rect.bottom - (rect.height * 0.2)),
    facetPaint,
  );
  canvas.drawLine(
    Offset(center.dx, rect.bottom - (rect.height * 0.2)),
    Offset(rect.right - (rect.width * 0.22), center.dy),
    facetPaint,
  );

  final Paint cornerSparkPaint = Paint()
    ..color = _withAlpha(
      Colors.white,
      (isCrystal ? (intenseGlow ? 0.54 : 0.32) : 0.36) * opacity,
    );
  if (intenseGlow || isCrystal) {
    cornerSparkPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.1);
  }
  final double spark = rect.width * 0.052;
  canvas.drawCircle(
    Offset(rect.left + (rect.width * 0.18), rect.top + (rect.height * 0.2)),
    spark,
    cornerSparkPaint,
  );

  final Paint orbPaint = Paint()
    ..shader = RadialGradient(
      colors: <Color>[
        _withAlpha(Colors.white, 0.42 * opacity),
        _withAlpha(cyanMix, 0.24 * opacity),
        _withAlpha(violetMix, 0.16 * opacity),
        Colors.transparent,
      ],
      stops: const <double>[0, 0.34, 0.6, 1],
    ).createShader(Rect.fromCircle(
      center: center,
      radius: rect.width * 0.28,
    ));
  canvas.drawCircle(center, rect.width * 0.2, orbPaint);
}

final Paint _occupiedPiecesBlitPaint = Paint()..filterQuality = FilterQuality.low;

/// Rasterises occupied cells and background stars of a Classic board into a [ui.Image].
///
/// Follows the same pattern as [rasterizeBoardWell]:
/// Paints in logical pixels on a canvas scaled by [devicePixelRatio], producing
/// physical pixel dimensions [ceil(width * ratio)] x [ceil(height * ratio)].
/// The caller owns the resulting [ui.Image] and is responsible for disposing it.
ui.Image rasterizeOccupiedCellsImage({
  required double width,
  required double height,
  required double cellSize,
  required Iterable<BoardCell> occupiedCells,
  required double devicePixelRatio,
  required Color occupiedColor,
  required BlockVisualPreset visualPreset,
  List<Offset>? starMap,
}) {
  final double ratio = devicePixelRatio > 0 ? devicePixelRatio : 1.0;
  final PictureRecorder recorder = PictureRecorder();
  final Canvas cacheCanvas = Canvas(recorder);
  cacheCanvas.scale(ratio);

  if (starMap != null && starMap.isNotEmpty) {
    final Paint starCorePaint = Paint()..color = const Color(0x2999D3EE);
    final Paint starAuraPaint = Paint()
      ..color = const Color(0x1492D3F4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8);
    cacheCanvas.save();
    cacheCanvas.clipRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(18),
    ));
    for (int i = 0; i < starMap.length; i++) {
      if (i % 2 != 0) {
        continue;
      }
      final Offset uv = starMap[i];
      final Offset point = Offset(width * uv.dx, height * uv.dy);
      cacheCanvas.drawCircle(point, cellSize * 0.013, starAuraPaint);
      cacheCanvas.drawCircle(point, cellSize * 0.005, starCorePaint);
    }
    cacheCanvas.restore();
  }

  for (final BoardCell cell in occupiedCells) {
    final double tone =
        ((math.sin((cell.x * 0.92) + (cell.y * 1.17)) + 1) / 2)
            .clamp(0, 1)
            .toDouble();
    final Color coolTint =
        _mixColor(occupiedColor, const Color(0xFFA9EEFF), 0.34);
    final Color violetTint =
        _mixColor(occupiedColor, const Color(0xFFCAAFFF), 0.3);
    final Color occupiedTint = _mixColor(violetTint, coolTint, tone);
    final Rect occupiedRect = Rect.fromLTWH(
      cell.x * cellSize + 4,
      cell.y * cellSize + 4,
      cellSize - 8,
      cellSize - 8,
    );
    _drawGlassBlockCell(
      cacheCanvas,
      rect: occupiedRect,
      tint: occupiedTint,
      preset: visualPreset,
      opacity: 0.88,
      intenseGlow: true,
    );
  }

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = picture.toImageSync(
    math.max(1, (width * ratio).ceil()),
    math.max(1, (height * ratio).ceil()),
  );
  picture.dispose();
  return image;
}

/// Draws an image created by [rasterizeOccupiedCellsImage] to [canvas].
void drawOccupiedCellsImage(
  Canvas canvas,
  ui.Image image, {
  required double width,
  required double height,
  Paint? paint,
}) {
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromLTWH(0, 0, width, height),
    paint ?? _occupiedPiecesBlitPaint,
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
  double _dangerPulseTime = 0;

  @override
  void update(double dt) {
    super.update(dt);
    final double fillRatio =
        _boardState.occupiedCells.length / (_boardState.size * _boardState.size);
    if (fillRatio > 0.75 && !Step6Benchmark.reducedMotion.value) {
      _dangerPulseTime += dt;
    } else {
      _dangerPulseTime = 0;
    }
  }

  ui.Image? _boardWellImage;
  Vector2 _boardWellSize = Vector2.zero();
  double _boardWellRatio = 0;
  Color _boardWellBgColor = const Color(0x00000000);
  Color _boardWellOccupiedColor = const Color(0x00000000);
  int _boardWellGridSize = 0;

  ui.Image? _cachedPiecesImage;
  Vector2 _cachedPiecesSize = Vector2.zero();
  double _cachedPiecesRatio = 0;

  void setBoardState(BoardState boardState) {
    _boardState = boardState;
    _cachedPiecesImage?.dispose();
    _cachedPiecesImage = null;
  }

  @override
  void onRemove() {
    dropCachedSurfaces();
    super.onRemove();
  }

  /// Releases every GPU-resident surface this component caches.
  ///
  /// `toImageSync` hands back an image that lives on the GPU, and a surface
  /// can be torn down and rebuilt underneath us - backgrounding the app is the
  /// common way. Dropping the caches costs one re-rasterisation and removes
  /// the question of whether an image outlived its context.
  void dropCachedSurfaces() {
    final ui.Image? staleWell = _boardWellImage;
    _boardWellImage = null;
    staleWell?.dispose();

    final ui.Image? stalePieces = _cachedPiecesImage;
    _cachedPiecesImage = null;
    stalePieces?.dispose();
  }

  void setPreview({
    required Piece piece,
    required int anchorX,
    required int anchorY,
    required bool valid,
  }) {
    Set<int> clearingRows = const <int>{};
    Set<int> clearingCols = const <int>{};
    if (valid) {
      final Set<BoardCell> simulated = <BoardCell>{..._boardState.occupiedCells};
      for (final PieceCellOffset offset in piece.cells) {
        final int x = anchorX + offset.dx;
        final int y = anchorY + offset.dy;
        if (x >= 0 && x < _boardState.size && y >= 0 && y < _boardState.size) {
          simulated.add(BoardCell(x: x, y: y));
        }
      }
      final Set<int> rows = <int>{};
      final Set<int> cols = <int>{};
      for (int y = 0; y < _boardState.size; y++) {
        bool full = true;
        for (int x = 0; x < _boardState.size; x++) {
          if (!simulated.contains(BoardCell(x: x, y: y))) {
            full = false;
            break;
          }
        }
        if (full) {
          rows.add(y);
        }
      }
      for (int x = 0; x < _boardState.size; x++) {
        bool full = true;
        for (int y = 0; y < _boardState.size; y++) {
          if (!simulated.contains(BoardCell(x: x, y: y))) {
            full = false;
            break;
          }
        }
        if (full) {
          cols.add(x);
        }
      }
      clearingRows = rows;
      clearingCols = cols;
    }

    _previewState = _PreviewState(
      piece: piece,
      anchorX: anchorX,
      anchorY: anchorY,
      valid: valid,
      clearingRows: clearingRows,
      clearingCols: clearingCols,
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
    _cachedPiecesImage?.dispose();
    _cachedPiecesImage = null;
  }

  void setVisualPreset(BlockVisualPreset preset) {
    _visualPreset = preset;
    _cachedPiecesImage?.dispose();
    _cachedPiecesImage = null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final double cellSize = size.x / _boardState.size;
    final double ratio = boardWellPixelRatio();

    if (_boardWellImage == null ||
        _boardWellSize != size ||
        _boardWellRatio != ratio ||
        _boardWellBgColor != _boardBackgroundColor ||
        _boardWellOccupiedColor != _occupiedColor ||
        _boardWellGridSize != _boardState.size) {
      // Clear the field before disposing, never after. If the rasterisation
      // below throws, whatever is left in the field is drawn on the next
      // frame, and drawing a disposed ui.Image is a native crash, not a Dart
      // exception: the zone guard never sees it and the app simply closes.
      final ui.Image? staleWell = _boardWellImage;
      _boardWellImage = null;
      staleWell?.dispose();
      _boardWellImage = rasterizeBoardWell(
        width: size.x,
        height: size.y,
        cell: cellSize,
        cols: _boardState.size,
        rows: _boardState.size,
        devicePixelRatio: ratio,
        cornerRadius: 18,
        socketStrength: 0.5,
        tint: _boardBackgroundColor,
        accent: _occupiedColor,
      );
      _boardWellSize = size.clone();
      _boardWellRatio = ratio;
      _boardWellBgColor = _boardBackgroundColor;
      _boardWellOccupiedColor = _occupiedColor;
      _boardWellGridSize = _boardState.size;
    }

    final ui.Image? wellImage = _boardWellImage;
    if (wellImage != null) {
      drawBoardWellImage(
        canvas,
        wellImage,
        width: size.x,
        height: size.y,
      );
    }

    if (_cachedPiecesImage == null ||
        _cachedPiecesSize != size ||
        _cachedPiecesRatio != ratio) {
      _cachedPiecesSize = size.clone();
      _cachedPiecesRatio = ratio;
      final ui.Image? stalePieces = _cachedPiecesImage;
      _cachedPiecesImage = null;
      stalePieces?.dispose();
      _cachedPiecesImage = rasterizeOccupiedCellsImage(
        width: size.x,
        height: size.y,
        cellSize: cellSize,
        occupiedCells: _boardState.occupiedCells,
        devicePixelRatio: ratio,
        occupiedColor: _occupiedColor,
        visualPreset: _visualPreset,
        starMap: _starMap,
      );
    }

    if (!Step1jDecomposition.hideD && _cachedPiecesImage != null) {
      drawOccupiedCellsImage(
        canvas,
        _cachedPiecesImage!,
        width: size.x,
        height: size.y,
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
          x * cellSize + 6,
          y * cellSize + 6,
          cellSize - 12,
          cellSize - 12,
        );
        _drawGlassBlockCell(
          canvas,
          rect: hintRect,
          tint: const Color(0xFF9BD9FF),
          preset: _visualPreset,
          opacity: 0.38,
        );
      }
    }

    final _PreviewState? preview = _previewState;
    if (preview != null) {
      // Pre-clear highlight: lines about to be cleared catch light before drop.
      if (preview.clearingRows.isNotEmpty || preview.clearingCols.isNotEmpty) {
        final Paint lineGlow = Paint()
          ..color = const Color(0x355DE8FF)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cellSize * 0.12);
        final Paint lineLip = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.4, cellSize * 0.04)
          ..color = const Color(0x75A5F4FF);

        for (final int r in preview.clearingRows) {
          final Rect rRect =
              Rect.fromLTWH(0, (r * cellSize) + 2, size.x, cellSize - 4);
          final RRect rr = RRect.fromRectAndRadius(
            rRect,
            Radius.circular(cellSize * 0.18),
          );
          canvas.drawRRect(rr, lineGlow);
          canvas.drawRRect(rr, lineLip);
        }
        for (final int c in preview.clearingCols) {
          final Rect cRect =
              Rect.fromLTWH((c * cellSize) + 2, 0, cellSize - 4, size.y);
          final RRect rr = RRect.fromRectAndRadius(
            cRect,
            Radius.circular(cellSize * 0.18),
          );
          canvas.drawRRect(rr, lineGlow);
          canvas.drawRRect(rr, lineLip);
        }
      }

      final Color previewTint =
          preview.valid ? const Color(0xFFA0E6FF) : const Color(0xFFFF7E97);
      for (final PieceCellOffset offset in preview.piece.cells) {
        final int x = preview.anchorX + offset.dx;
        final int y = preview.anchorY + offset.dy;
        if (x < 0 || y < 0 || x >= _boardState.size || y >= _boardState.size) {
          continue;
        }

        final Rect previewRect = Rect.fromLTWH(
          x * cellSize + 5,
          y * cellSize + 5,
          cellSize - 10,
          cellSize - 10,
        );
        _drawGlassBlockCell(
          canvas,
          rect: previewRect,
          tint: previewTint,
          preset: _visualPreset,
          opacity: preview.valid ? 0.62 : 0.5,
          intenseGlow: preview.valid,
        );
      }
    }

    final double fillRatio =
        _boardState.occupiedCells.length / (_boardState.size * _boardState.size);
    if (fillRatio > 0.75 && !Step6Benchmark.reducedMotion.value) {
      // DEC-0028 Item 17: Danger Edge Pulse (fill > 75%, alpha 0.15–0.25, 1.5s period)
      final double cycle = (_dangerPulseTime % 1.5) / 1.5;
      final double sineVal = (math.sin(cycle * 2 * math.pi) + 1.0) / 2.0;
      final double pulseAlpha = 0.15 + (0.25 - 0.15) * sineVal;

      final Rect borderRect = Rect.fromLTWH(1.5, 1.5, size.x - 3.0, size.y - 3.0);
      final RRect borderRRect = RRect.fromRectAndRadius(borderRect, const Radius.circular(18));

      final Paint pulseGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..color = const Color(0xFFFF3D00).withValues(alpha: pulseAlpha * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(borderRRect, pulseGlow);

      final Paint pulseBorder = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = const Color(0xFFFF5252).withValues(alpha: pulseAlpha);
      canvas.drawRRect(borderRRect, pulseBorder);
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
    required this.haptics,
    this.vfxDirector,
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
  final HapticsController haptics;
  final VfxDirector? vfxDirector;
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
  
  Picture? _cachedPicture;
  bool _cachedIsDragging = false;

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
      // toList() first: whereType over children is lazy, and removeAll
      // deletes from the very collection it is walking. Placing a piece
      // while one of these effects was still running threw a
      // ConcurrentModificationError straight out of the drop handler.
      removeAll(children.whereType<MoveToEffect>().toList());
      add(
        MoveToEffect(
          _homePosition.clone(),
          EffectController(duration: 0.2, curve: Curves.easeOutQuad),
        ),
      );
    }
  }

  void resetToHome() {
    removeAll(children.whereType<MoveToEffect>().toList());
    add(
      MoveToEffect(
        _homePosition.clone(),
        EffectController(duration: 0.25, curve: Curves.easeOutQuad),
      ),
    );
    _clearDragState();
  }

  void updatePalette({
    required Color baseColor,
    required Color dragColor,
  }) {
    _baseColor = baseColor;
    _dragColor = dragColor;
    dropCachedSurfaces();
  }

  void updateVisualPreset(BlockVisualPreset preset) {
    _visualPreset = preset;
    dropCachedSurfaces();
  }

  /// Disposes the recorded piece and clears the field.
  ///
  /// A `Picture` holds native memory that the garbage collector does not
  /// account for, so dropping the reference without disposing leaks it. This
  /// used to happen on every palette change, every preset change and every
  /// drag, because dragging re-records the piece in its drag colour.
  void dropCachedSurfaces() {
    final Picture? stale = _cachedPicture;
    _cachedPicture = null;
    stale?.dispose();
  }

  @override
  void onRemove() {
    dropCachedSurfaces();
    super.onRemove();
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
    
    final bool isDragging = _dragging;
    if (_cachedPicture == null || _cachedIsDragging != isDragging) {
      dropCachedSurfaces();
      _cachedIsDragging = isDragging;
      final PictureRecorder recorder = PictureRecorder();
      final Canvas cacheCanvas = Canvas(recorder);
      
      final Color tint = isDragging ? _dragColor : _baseColor;
      for (final PieceCellOffset cell in piece.cells) {
        final double tone =
            ((math.sin((cell.dx * 0.95) + (cell.dy * 1.12)) + 1) / 2)
                .clamp(0, 1)
                .toDouble();
        final Color coolTint = _mixColor(tint, const Color(0xFFA9EEFF), 0.34);
        final Color violetTint = _mixColor(tint, const Color(0xFFCAAFFF), 0.3);
        final Color cellTint = _mixColor(violetTint, coolTint, tone);
        final Rect rect = Rect.fromLTWH(
          (cell.dx * cellSize) + 3,
          (cell.dy * cellSize) + 3,
          cellSize - 6,
          cellSize - 6,
        );
        _drawGlassBlockCell(
          cacheCanvas,
          rect: rect,
          tint: cellTint,
          preset: _visualPreset,
          opacity: 0.9,
          intenseGlow: true,
        );
      }
      _cachedPicture = recorder.endRecording();
    }

    final double scale = lerpDouble(1, 1.035, _dragVisualProgress) ?? 1;
    final Picture? piecePicture = _cachedPicture;
    if (!Step1jDecomposition.hideE && piecePicture != null) {
      if ((scale - 1).abs() > 0.0001) {
        canvas.save();
        final double cx = size.x * 0.5;
        final double cy = size.y * 0.5;
        canvas.translate(cx, cy);
        canvas.scale(scale, scale);
        canvas.translate(-cx, -cy);

        if (_dragging && (vfxDirector?.auraShader.isEnabled ?? false)) {
          final Rect pieceBounds = Rect.fromLTWH(0, 0, size.x, size.y);
          vfxDirector!.auraShader.drawAura(
            canvas,
            targetBounds: pieceBounds,
            color: _dragColor,
            time: vfxDirector!.clock,
            intensity: _dragVisualProgress,
          );
        }

        canvas.drawPicture(piecePicture);
        canvas.restore();
      } else {
        canvas.drawPicture(piecePicture);
      }
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

  /// Calculates the horizontal shift required to center the piece horizontally on the touch point.
  static double horizontalCenterOffset({
    required double localTouchX,
    required double pieceWidth,
  }) {
    return localTouchX - (pieceWidth * 0.5);
  }

  @override
  void onDragStart(DragStartEvent event) {
    removeAll(children.whereType<MoveToEffect>().toList());
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
      unawaited(haptics.lightImpact());
    }
    // DEC-0024 point 5: Center horizontally on the piece's bounding box.
    // Horizontal centring makes left/right placement predictable.
    // Vertical lift (_touchDragLiftPixels = 50) is kept intact above so
    // the piece stays visible above the finger.
    final double hOffset = horizontalCenterOffset(
      localTouchX: event.localPosition.x,
      pieceWidth: size.x,
    );
    position.x += hOffset;

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
    this.clearingRows = const <int>{},
    this.clearingCols = const <int>{},
  });

  final Piece piece;
  final int anchorX;
  final int anchorY;
  final bool valid;
  final Set<int> clearingRows;
  final Set<int> clearingCols;
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

/// Geometric centroid calculator for cleared cells.
Vector2 computeClearedCentroid({
  required Iterable<BoardCell> cells,
  required Vector2 boardOrigin,
  required double cellSize,
}) {
  if (cells.isEmpty) {
    return boardOrigin.clone();
  }
  double sumX = 0;
  double sumY = 0;
  for (final BoardCell c in cells) {
    sumX += c.x;
    sumY += c.y;
  }
  final double cx = boardOrigin.x + (((sumX / cells.length) + 0.5) * cellSize);
  final double cy = boardOrigin.y + (((sumY / cells.length) + 0.5) * cellSize);
  return Vector2(cx, cy);
}

class _Step6BenchRunnerComponent extends Component {
  _Step6BenchRunnerComponent(this.game);

  final BlockPuzzleGame game;
  final List<double> _eventTimers =
      List<double>.generate(8, (int i) => (7 - i) * 0.1);
  static const double _eventDuration = 0.8;

  @override
  void update(double dt) {
    super.update(dt);
    if (!kDiagnosticsEnabled || !Step6Benchmark.benchActive.value) {
      return;
    }
    if (Step6Benchmark.scenario.value == Step6BenchmarkScenario.tripleClear) {
      _eventTimers[0] += dt;
      if (_eventTimers[0] >= 0.4) {
        _eventTimers[0] -= 0.4;
        if (Step6Benchmark.effectsEnabled.value) {
          game.triggerStep6BenchEvent(0);
        }
      }
      return;
    }
    for (int i = 0; i < 8; i++) {
      _eventTimers[i] += dt;
      if (_eventTimers[i] >= _eventDuration) {
        _eventTimers[i] -= _eventDuration;
        if (Step6Benchmark.effectsEnabled.value) {
          game.triggerStep6BenchEvent(i);
        }
      }
    }
  }
}
