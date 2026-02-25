import '../gameplay/piece.dart';

class PieceTriplet {
  PieceTriplet({
    required this.pieces,
  }) : assert(pieces.length == 3);

  final List<Piece> pieces;
}
