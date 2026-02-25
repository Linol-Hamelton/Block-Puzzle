import 'piece.dart';

class Move {
  const Move({
    required this.piece,
    required this.anchorX,
    required this.anchorY,
  });

  final Piece piece;
  final int anchorX;
  final int anchorY;
}
