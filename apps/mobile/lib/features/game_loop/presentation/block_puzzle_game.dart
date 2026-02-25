import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';

import '../../../domain/gameplay/board_state.dart';
import '../../../domain/gameplay/move.dart';
import '../../../domain/gameplay/piece.dart';
import '../audio/game_sfx_player.dart';
import '../application/game_loop_controller.dart';

class BlockPuzzleGame extends FlameGame {
  BlockPuzzleGame({
    required this.controller,
    required this.sfxPlayer,
  });

  final GameLoopController controller;
  final GameSfxPlayer sfxPlayer;

  late final BoardComponent _boardComponent;
  final List<RackPieceComponent> _rackComponents = <RackPieceComponent>[];
  late final VoidCallback _stateListener;

  double _boardCellSize = 36;
  Vector2 _boardOrigin = Vector2.zero();
  bool _dropInProgress = false;

  static const double _rackCellSize = 24;

  @override
  Future<void> onLoad() async {
    await sfxPlayer.preload();
    await controller.initialize();

    _boardComponent = BoardComponent();
    add(_boardComponent);

    _stateListener = _syncWithState;
    controller.stateListenable.addListener(_stateListener);
    _syncWithState();

    await super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _recalculateLayout();
    _positionRackPieces();
  }

  @override
  void onRemove() {
    controller.stateListenable.removeListener(_stateListener);
    super.onRemove();
  }

  void onRackPieceDragged(RackPieceComponent pieceComponent) {
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
    final state = controller.state;
    _recalculateLayout();
    _boardComponent.setBoardState(state.boardState);
    _rebuildRackPieces(state.rackPieces);
  }

  void _recalculateLayout() {
    final double boardPixels = math.min(
      size.x - 32,
      360,
    );
    _boardCellSize = boardPixels / 8;
    _boardOrigin = Vector2((size.x - boardPixels) / 2, 42);

    _boardComponent
      ..position = _boardOrigin
      ..size = Vector2.all(boardPixels);
  }

  void _rebuildRackPieces(List<Piece> pieces) {
    for (final RackPieceComponent component in _rackComponents) {
      component.removeFromParent();
    }
    _rackComponents.clear();

    for (int i = 0; i < pieces.length; i++) {
      final RackPieceComponent component = RackPieceComponent(
        piece: pieces[i],
        cellSize: _rackCellSize,
        homePosition: _rackPositionFor(index: i, piece: pieces[i]),
        onDragMoved: onRackPieceDragged,
        onDropped: onRackPieceDropped,
      );
      _rackComponents.add(component);
      add(component);
    }
  }

  void _positionRackPieces() {
    for (int i = 0; i < _rackComponents.length; i++) {
      final RackPieceComponent component = _rackComponents[i];
      component.updateHome(
        _rackPositionFor(
          index: i,
          piece: component.piece,
        ),
      );
    }
  }

  Vector2 _rackPositionFor({
    required int index,
    required Piece piece,
  }) {
    final Vector2 pieceSize = RackPieceComponent.visualSize(
      piece: piece,
      cellSize: _rackCellSize,
    );
    final double rackY = _boardOrigin.y + (_boardCellSize * 8) + 28;
    final double slotCenterX = size.x * ((index + 1) / 4);
    return Vector2(slotCenterX - (pieceSize.x / 2), rackY);
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

class BoardComponent extends PositionComponent {
  BoardState _boardState = BoardState.empty(size: 8);
  _PreviewState? _previewState;

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

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final double cellSize = size.x / _boardState.size;
    final Paint boardBackground = Paint()..color = const Color(0xFFEAF0F5);
    final Paint gridPaint = Paint()
      ..color = const Color(0xFFC7D4E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final Paint occupiedPaint = Paint()..color = const Color(0xFF0A4D68);
    final Paint previewValidPaint = Paint()..color = const Color(0x8021A179);
    final Paint previewInvalidPaint = Paint()..color = const Color(0x80D64545);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(14),
      ),
      boardBackground,
    );

    for (int y = 0; y < _boardState.size; y++) {
      for (int x = 0; x < _boardState.size; x++) {
        final Rect cellRect = Rect.fromLTWH(
          x * cellSize,
          y * cellSize,
          cellSize,
          cellSize,
        );
        canvas.drawRect(cellRect, gridPaint);
      }
    }

    for (final BoardCell cell in _boardState.occupiedCells) {
      final Rect occupiedRect = Rect.fromLTWH(
        cell.x * cellSize + 2,
        cell.y * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(occupiedRect, const Radius.circular(6)),
        occupiedPaint,
      );
    }

    final _PreviewState? preview = _previewState;
    if (preview != null) {
      final Paint previewPaint =
          preview.valid ? previewValidPaint : previewInvalidPaint;
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
        canvas.drawRRect(
          RRect.fromRectAndRadius(previewRect, const Radius.circular(6)),
          previewPaint,
        );
      }
    }
  }
}

class RackPieceComponent extends PositionComponent with DragCallbacks {
  RackPieceComponent({
    required this.piece,
    required this.cellSize,
    required Vector2 homePosition,
    required this.onDragMoved,
    required this.onDropped,
  }) : _homePosition = homePosition.clone() {
    size = visualSize(
      piece: piece,
      cellSize: cellSize,
    );
    position = _homePosition.clone();
  }

  final Piece piece;
  final double cellSize;
  final void Function(RackPieceComponent component) onDragMoved;
  final Future<void> Function(RackPieceComponent component) onDropped;
  Vector2 _homePosition;
  bool _dragging = false;

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
    _dragging = false;
    priority = 0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final Paint paint = Paint()
      ..color = _dragging ? const Color(0xFF1A759F) : const Color(0xFF18536E);

    for (final PieceCellOffset cell in piece.cells) {
      final Rect rect = Rect.fromLTWH(
        (cell.dx * cellSize) + 1,
        (cell.dy * cellSize) + 1,
        cellSize - 2,
        cellSize - 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        paint,
      );
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    _dragging = true;
    priority = 100;
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
    onDragMoved(this);
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    _dragging = false;
    priority = 0;
    unawaited(onDropped(this));
    super.onDragEnd(event);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    resetToHome();
    super.onDragCancel(event);
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
