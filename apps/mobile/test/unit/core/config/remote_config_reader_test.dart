import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/core/config/remote_config_reader.dart';

void main() {
  group('RemoteConfigReader', () {
    group('readBool', () {
      test('returns bool value directly', () {
        final reader = const RemoteConfigReader(<String, Object?>{
          'flag_true': true,
          'flag_false': false,
        });

        expect(reader.readBool('flag_true', fallback: false), isTrue);
        expect(reader.readBool('flag_false', fallback: true), isFalse);
      });

      test('parses string "true" and "false"', () {
        final reader = const RemoteConfigReader(<String, Object?>{
          'str_true': 'true',
          'str_TRUE': 'TRUE',
          'str_false': 'false',
          'str_False': ' False ',
        });

        expect(reader.readBool('str_true', fallback: false), isTrue);
        expect(reader.readBool('str_TRUE', fallback: false), isTrue);
        expect(reader.readBool('str_false', fallback: true), isFalse);
        expect(reader.readBool('str_False', fallback: true), isFalse);
      });

      test('treats positive numbers as true', () {
        final reader = const RemoteConfigReader(<String, Object?>{
          'num_pos': 1,
          'num_pos_float': 0.5,
          'num_zero': 0,
          'num_neg': -1,
        });

        expect(reader.readBool('num_pos', fallback: false), isTrue);
        expect(reader.readBool('num_pos_float', fallback: false), isTrue);
        expect(reader.readBool('num_zero', fallback: true), isFalse);
        expect(reader.readBool('num_neg', fallback: true), isFalse);
      });

      test('returns fallback for missing keys', () {
        final reader = const RemoteConfigReader(<String, Object?>{});

        expect(reader.readBool('missing', fallback: true), isTrue);
        expect(reader.readBool('missing', fallback: false), isFalse);
      });

      test('returns fallback for null values', () {
        final reader = const RemoteConfigReader(<String, Object?>{
          'null_val': null,
        });

        expect(reader.readBool('null_val', fallback: true), isTrue);
      });

      test('returns fallback for unparseable strings', () {
        final reader = const RemoteConfigReader(<String, Object?>{
          'garbage': 'maybe',
        });

        expect(reader.readBool('garbage', fallback: true), isTrue);
        expect(reader.readBool('garbage', fallback: false), isFalse);
      });
    });

    group('readInt', () {
      test('returns int value directly', () {
        final reader = const RemoteConfigReader(<String, Object?>{
          'count': 42,
        });

        expect(reader.readInt('count', fallback: 0), 42);
      });

      test('converts double to int', () {
        final reader = const RemoteConfigReader(<String, Object?>{
          'float_val': 3.7,
        });

        expect(reader.readInt('float_val', fallback: 0), 3);
      });

      test('parses string integers', () {
        final reader = const RemoteConfigReader(<String, Object?>{
          'str_int': '123',
        });

        expect(reader.readInt('str_int', fallback: 0), 123);
      });

      test('returns fallback for unparseable strings', () {
        final reader = const RemoteConfigReader(<String, Object?>{
          'bad': 'hello',
        });

        expect(reader.readInt('bad', fallback: 99), 99);
      });

      test('returns fallback for missing keys', () {
        final reader = const RemoteConfigReader(<String, Object?>{});

        expect(reader.readInt('missing', fallback: 7), 7);
      });
    });

    group('readString', () {
      test('returns non-empty string value', () {
        final reader = const RemoteConfigReader(<String, Object?>{
          'name': 'hello',
        });

        expect(reader.readString('name', fallback: 'default'), 'hello');
      });

      test('trims whitespace', () {
        final reader = const RemoteConfigReader(<String, Object?>{
          'padded': '  value  ',
        });

        expect(reader.readString('padded', fallback: 'default'), 'value');
      });

      test('returns fallback for empty string', () {
        final reader = const RemoteConfigReader(<String, Object?>{
          'empty': '',
          'spaces': '   ',
        });

        expect(reader.readString('empty', fallback: 'fb'), 'fb');
        expect(reader.readString('spaces', fallback: 'fb'), 'fb');
      });

      test('returns fallback for missing keys', () {
        final reader = const RemoteConfigReader(<String, Object?>{});

        expect(reader.readString('missing', fallback: 'x'), 'x');
      });

      test('returns fallback for non-string values', () {
        final reader = const RemoteConfigReader(<String, Object?>{
          'num': 42,
          'bool': true,
        });

        expect(reader.readString('num', fallback: 'fb'), 'fb');
        expect(reader.readString('bool', fallback: 'fb'), 'fb');
      });
    });

    group('raw', () {
      test('exposes the underlying config map', () {
        final config = <String, Object?>{'key': 'value'};
        final reader = RemoteConfigReader(config);

        expect(reader.raw, config);
      });
    });
  });
}
