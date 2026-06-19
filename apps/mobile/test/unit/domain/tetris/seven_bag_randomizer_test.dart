import 'package:block_puzzle_mobile/domain/tetris/seven_bag_randomizer.dart';
import 'package:block_puzzle_mobile/domain/tetris/tetromino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SevenBagRandomizer', () {
    test('each bag of 7 contains all seven types exactly once', () {
      final SevenBagRandomizer bag = SevenBagRandomizer(seed: 42);
      final List<TetrominoType> first =
          List<TetrominoType>.generate(7, (_) => bag.next());
      expect(first.toSet().length, 7);
      expect(first.toSet(), TetrominoType.values.toSet());
    });

    test('two consecutive bags each contain all seven types', () {
      final SevenBagRandomizer bag = SevenBagRandomizer(seed: 7);
      final List<TetrominoType> drawn =
          List<TetrominoType>.generate(14, (_) => bag.next());
      expect(drawn.sublist(0, 7).toSet(), TetrominoType.values.toSet());
      expect(drawn.sublist(7, 14).toSet(), TetrominoType.values.toSet());
    });

    test('same seed yields an identical sequence (daily-challenge parity)', () {
      final SevenBagRandomizer a = SevenBagRandomizer(seed: 123);
      final SevenBagRandomizer b = SevenBagRandomizer(seed: 123);
      final List<TetrominoType> seqA =
          List<TetrominoType>.generate(21, (_) => a.next());
      final List<TetrominoType> seqB =
          List<TetrominoType>.generate(21, (_) => b.next());
      expect(seqA, seqB);
    });

    test('peek does not consume', () {
      final SevenBagRandomizer bag = SevenBagRandomizer(seed: 1);
      final List<TetrominoType> preview = bag.peek(5);
      expect(preview.length, 5);
      final List<TetrominoType> taken =
          List<TetrominoType>.generate(5, (_) => bag.next());
      expect(taken, preview);
    });
  });
}
