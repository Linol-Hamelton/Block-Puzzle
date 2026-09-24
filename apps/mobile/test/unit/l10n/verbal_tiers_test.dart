import 'package:block_puzzle_mobile/l10n/verbal_tiers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VerbalTiers', () {
    test('resolves English tiers accurately across all combo streaks', () {
      expect(VerbalTiers.resolve(comboStreak: 1), isEmpty);
      expect(VerbalTiers.resolve(comboStreak: 2), 'NICE!');
      expect(VerbalTiers.resolve(comboStreak: 3), 'NICE!');
      expect(VerbalTiers.resolve(comboStreak: 4), 'GREAT!');
      expect(VerbalTiers.resolve(comboStreak: 5), 'GREAT!');
      expect(VerbalTiers.resolve(comboStreak: 6), 'AMAZING!');
      expect(VerbalTiers.resolve(comboStreak: 7), 'AMAZING!');
      expect(VerbalTiers.resolve(comboStreak: 8), 'UNSTOPPABLE!');
      expect(VerbalTiers.resolve(comboStreak: 12), 'UNSTOPPABLE!');
    });

    test('resolves Russian tiers accurately', () {
      expect(VerbalTiers.resolve(comboStreak: 1, locale: 'ru'), isEmpty);
      expect(VerbalTiers.resolve(comboStreak: 2, locale: 'ru'), 'ХОРОШО!');
      expect(VerbalTiers.resolve(comboStreak: 3, locale: 'ru'), 'ХОРОШО!');
      expect(VerbalTiers.resolve(comboStreak: 4, locale: 'ru'), 'ОТЛИЧНО!');
      expect(VerbalTiers.resolve(comboStreak: 5, locale: 'ru'), 'ОТЛИЧНО!');
      expect(VerbalTiers.resolve(comboStreak: 6, locale: 'ru'), 'НЕВЕРОЯТНО!');
      expect(VerbalTiers.resolve(comboStreak: 7, locale: 'ru'), 'НЕВЕРОЯТНО!');
      expect(VerbalTiers.resolve(comboStreak: 8, locale: 'ru'), 'НЕОСТАНОВИМ!');
    });
  });
}
