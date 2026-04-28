import 'dart:convert';

import '../gameplay/board_state.dart';
import '../gameplay/piece.dart';
import '../scoring/score_state.dart';

class GameSnapshot {
  const GameSnapshot({
    required this.boardState,
    required this.scoreState,
    required this.rackPieces,
    required this.level,
    required this.movesPlayed,
    required this.gamesPlayed,
    this.isDailyChallenge = false,
  });

  final BoardState boardState;
  final ScoreState scoreState;
  final List<Piece> rackPieces;
  final int level;
  final int movesPlayed;
  final int gamesPlayed;
  final bool isDailyChallenge;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'board_state': boardState.toJson(),
      'score_state': scoreState.toJson(),
      'rack_pieces': rackPieces.map((Piece p) => p.toJson()).toList(growable: false),
      'level': level,
      'moves_played': movesPlayed,
      'games_played': gamesPlayed,
      'is_daily_challenge': isDailyChallenge,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory GameSnapshot.fromJson(Map<String, Object?> json) {
    return GameSnapshot(
      boardState: BoardState.fromJson(
        (json['board_state'] as Map<dynamic, dynamic>?)?.cast<String, Object?>() ?? <String, Object?>{},
      ),
      scoreState: ScoreState.fromJson(
        (json['score_state'] as Map<dynamic, dynamic>?)?.cast<String, Object?>() ?? <String, Object?>{},
      ),
      rackPieces: (json['rack_pieces'] as List<dynamic>?)
              ?.map((dynamic e) => Piece.fromJson((e as Map<dynamic, dynamic>).cast<String, Object?>()))
              .toList(growable: false) ??
          <Piece>[],
      level: json['level'] as int? ?? 1,
      movesPlayed: json['moves_played'] as int? ?? 0,
      gamesPlayed: json['games_played'] as int? ?? 0,
      isDailyChallenge: json['is_daily_challenge'] as bool? ?? false,
    );
  }

  factory GameSnapshot.fromJsonString(String rawJson) {
    final Object? decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('GameSnapshot must be a JSON object.');
    }
    return GameSnapshot.fromJson(decoded.cast<String, Object?>());
  }
}
