class BoardState {
  BoardState({
    required this.size,
    required Set<BoardCell> occupiedCells,
  }) : occupiedCells = Set<BoardCell>.unmodifiable(occupiedCells);

  final int size;
  final Set<BoardCell> occupiedCells;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'size': size,
      'occupied_cells': occupiedCells.map((BoardCell c) => c.toJson()).toList(growable: false),
    };
  }

  factory BoardState.fromJson(Map<String, Object?> json) {
    return BoardState(
      size: json['size'] as int? ?? 8,
      occupiedCells: (json['occupied_cells'] as List<dynamic>?)
              ?.map((dynamic e) => BoardCell.fromJson(e as Map<String, Object?>))
              .toSet() ??
          <BoardCell>{},
    );
  }

  bool isOccupied(BoardCell cell) => occupiedCells.contains(cell);

  bool isInBounds(BoardCell cell) {
    return cell.x >= 0 && cell.y >= 0 && cell.x < size && cell.y < size;
  }

  BoardState placeCells(Iterable<BoardCell> cells) {
    return BoardState(
      size: size,
      occupiedCells: <BoardCell>{
        ...occupiedCells,
        ...cells,
      },
    );
  }

  BoardState removeCells(bool Function(BoardCell cell) predicate) {
    return BoardState(
      size: size,
      occupiedCells:
          occupiedCells.where((BoardCell cell) => !predicate(cell)).toSet(),
    );
  }

  factory BoardState.empty({int size = 8}) {
    return BoardState(
      size: size,
      occupiedCells: <BoardCell>{},
    );
  }
}

class BoardCell {
  const BoardCell({
    required this.x,
    required this.y,
  });

  final int x;
  final int y;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'x': x,
      'y': y,
    };
  }

  factory BoardCell.fromJson(Map<String, Object?> json) {
    return BoardCell(
      x: json['x'] as int? ?? 0,
      y: json['y'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BoardCell && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}
