class Piece {
  const Piece({
    required this.id,
    required this.cells,
  });

  final String id;
  final List<PieceCellOffset> cells;
}

class PieceCellOffset {
  const PieceCellOffset({
    required this.dx,
    required this.dy,
  });

  final int dx;
  final int dy;
}
