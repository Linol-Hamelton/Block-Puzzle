import 'package:block_puzzle_mobile/data/analytics/analytics_schema_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsSchemaValidator', () {
    const AnalyticsSchemaValidator validator = AnalyticsSchemaValidator();

    test('validates game_start payload with required fields', () {
      final AnalyticsValidationResult result = validator.validate(
        'game_start',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'round_id': 4,
          'mode': 'classic',
          'config_version': 'cfg-01',
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('returns invalid when required fields are missing', () {
      final AnalyticsValidationResult result = validator.validate(
        'ad_impression',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'placement': 'game_over_interstitial',
        },
      );

      expect(result.isValid, isFalse);
      expect(result.missingRequired, contains('ad_type'));
      expect(result.missingRequired, contains('network'));
    });

    test('marks unknown params as warnings without failing', () {
      final AnalyticsValidationResult result = validator.validate(
        'move_rejected',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'reason': 'invalid_move',
          'unexpected_param': 123,
        },
      );

      expect(result.isValid, isTrue);
      expect(result.unknownParams, contains('unexpected_param'));
      expect(result.warnings, isNotEmpty);
    });

    test('requires schema_version for any event', () {
      final AnalyticsValidationResult result = validator.validate(
        'game_loop_initialized',
        params: const <String, Object?>{},
      );

      expect(result.isValid, isFalse);
      expect(result.missingRequired, contains('schema_version'));
    });
  });
}
