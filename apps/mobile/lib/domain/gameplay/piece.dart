class Piece {
  const Piece({
    required this.id,
    required this.cells,
  });

  final String id;
  final List<PieceCellOffset> cells;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'cells': cells.map((PieceCellOffset c) => c.toJson()).toList(growable: false),
    };
  }

  factory Piece.fromJson(Map<String, Object?> json) {
    return Piece(
      id: json['id'] as String? ?? '',
      cells: (json['cells'] as List<dynamic>?)
              ?.map((dynamic e) => PieceCellOffset.fromJson(e as Map<String, Object?>))
              .toList(growable: false) ??
          <PieceCellOffset>[],
    );
  }
}

class PieceCellOffset {
  const PieceCellOffset({
    required this.dx,
    required this.dy,
  });

  final int dx;
  final int dy;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'dx': dx,
      'dy': dy,
    };
  }

  factory PieceCellOffset.fromJson(Map<String, Object?> json) {
    return PieceCellOffset(
      dx: json['dx'] as int? ?? 0,
      dy: json['dy'] as int? ?? 0,
    );
  }
}
