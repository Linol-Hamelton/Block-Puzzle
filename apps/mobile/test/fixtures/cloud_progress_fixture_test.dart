import 'dart:convert';
import 'dart:io';

import 'package:block_puzzle_mobile/domain/progression/player_progress_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Writes the exact document `CloudPlayerProgressRepository` sends to Firestore
/// into a JSON fixture the rules tests load.
///
/// This exists because the rules tests previously used a hand-written map of
/// flat camelCase fields that no part of the app has ever produced. All sixteen
/// passed while every real cloud save was denied, because they were checking an
/// invented shape. The fixture is generated from `PlayerProgressState.toJson()`
/// so the two cannot drift again: change the model and this test rewrites the
/// fixture, and the rules tests fail until the rules are updated to match.
///
/// Named `*_test.dart` on purpose: `flutter test` only discovers that
/// pattern, so under the old name this never ran in the suite and the
/// drift protection it exists for was not actually armed.
///
/// Run on its own with:
///   flutter test test/fixtures/cloud_progress_fixture_test.dart
void main() {
  test('cloud progress fixture matches the current model', () {
    final PlayerProgressState state = PlayerProgressState.initialForDay(
      DateTime.utc(2026, 9, 15),
    );

    // The envelope is built here the same way the repository builds it. If the
    // repository changes shape, this has to change with it - which is the point.
    final Map<String, Object?> document = <String, Object?>{
      'progress': state.toJson(),
      'lastSyncUtc': '2026-09-15T12:00:00.000Z',
    };

    final File file = File('test/fixtures/cloud_progress_document.json');
    final String encoded =
        '${const JsonEncoder.withIndent('  ').convert(document)}\n';

    if (!file.existsSync() || file.readAsStringSync() != encoded) {
      file.writeAsStringSync(encoded);
    }

    // Guard the properties the rules depend on, so a model change that breaks
    // the contract fails here with an explanation rather than in a rules test
    // with a permission error.
    expect(document.keys, unorderedEquals(<String>['progress', 'lastSyncUtc']));

    final Map<String, Object?> progress =
        document['progress']! as Map<String, Object?>;
    expect(
      progress.containsKey('schema_version'),
      isTrue,
      reason: 'the model uses snake_case; rules written for camelCase will deny',
    );
    expect(
      progress.containsKey('economy_state'),
      isTrue,
      reason: 'economy_state carries owned_product_ids, which is an entitlement '
          'and must not be writable by the client',
    );
    expect(
      progress.containsKey('cosmetics_state'),
      isTrue,
      reason: 'cosmetics_state carries unlocked_skin_ids, likewise',
    );
  });
}
