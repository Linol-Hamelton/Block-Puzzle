class DifficultyProfile {
  const DifficultyProfile({
    required this.hardPieceWeight,
    required this.maxHardPiecesPerTriplet,
  });

  final double hardPieceWeight;
  final int maxHardPiecesPerTriplet;

  static const DifficultyProfile initial = DifficultyProfile(
    hardPieceWeight: 0.2,
    maxHardPiecesPerTriplet: 1,
  );
}
