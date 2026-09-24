/// Verbal combo tiers per DEC-0028 Item 19.
///
/// Tiers:
/// - combo 2-3: NICE
/// - combo 4-5: GREAT
/// - combo 6-7: AMAZING
/// - combo 8+: UNSTOPPABLE
class VerbalTiers {
  const VerbalTiers._();

  static String resolve({
    required int comboStreak,
    String locale = 'en',
  }) {
    if (comboStreak <= 1) {
      return '';
    }
    if (locale.startsWith('ru')) {
      if (comboStreak <= 3) {
        return 'ХОРОШО!';
      } else if (comboStreak <= 5) {
        return 'ОТЛИЧНО!';
      } else if (comboStreak <= 7) {
        return 'НЕВЕРОЯТНО!';
      } else {
        return 'НЕОСТАНОВИМ!';
      }
    }

    if (comboStreak <= 3) {
      return 'NICE!';
    } else if (comboStreak <= 5) {
      return 'GREAT!';
    } else if (comboStreak <= 7) {
      return 'AMAZING!';
    } else {
      return 'UNSTOPPABLE!';
    }
  }
}
