import 'package:block_puzzle_mobile/core/config/remote_config_reader.dart';
import 'package:block_puzzle_mobile/core/di/di_container.dart';
import 'package:block_puzzle_mobile/features/game_modes/game_mode_availability.dart';
import 'package:block_puzzle_mobile/features/store/application/store_availability.dart';
import 'package:block_puzzle_mobile/ui/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() async {
    await sl.reset();
  });

  Widget buildSubject() {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }

  void setupDependencies({required bool storeEnabled}) {
    sl.registerSingleton<GameModeAvailability>(
      const GameModeAvailability(RemoteConfigReader(<String, Object?>{})),
    );
    sl.registerSingleton<StoreAvailability>(
      StoreAvailability(RemoteConfigReader(<String, Object?>{
        'iap.store_enabled': storeEnabled,
      })),
    );
  }

  group('HomeScreen monetization surface gating (DEC-0026 / DEC-0028 p.7)', () {
    testWidgets('in v1.0 (store disabled): Open Premium Store button is hidden',
        (WidgetTester tester) async {
      setupDependencies(storeEnabled: false);

      await tester.pumpWidget(buildSubject());

      // Gameplay options remain accessible
      expect(find.text('Start Classic'), findsOneWidget);
      expect(find.text('Play Tetris'), findsOneWidget);
      expect(find.text('Play Match 3'), findsOneWidget);
      expect(find.text('Daily Challenge'), findsOneWidget);

      // Store entry is completely hidden
      expect(find.text('Open Premium Store'), findsNothing);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
    });

    testWidgets('gracefully defaults to hidden when StoreAvailability is not registered',
        (WidgetTester tester) async {
      sl.registerSingleton<GameModeAvailability>(
        const GameModeAvailability(RemoteConfigReader(<String, Object?>{})),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.text('Open Premium Store'), findsNothing);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
    });

    testWidgets('in Stage C (store enabled): Open Premium Store button is visible',
        (WidgetTester tester) async {
      setupDependencies(storeEnabled: true);

      await tester.pumpWidget(buildSubject());

      // Gameplay options remain accessible
      expect(find.text('Start Classic'), findsOneWidget);
      expect(find.text('Daily Challenge'), findsOneWidget);

      // Store entry is visible
      expect(find.text('Open Premium Store'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    });
  });
}
