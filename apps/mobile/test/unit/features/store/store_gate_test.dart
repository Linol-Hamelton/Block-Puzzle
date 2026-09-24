import 'package:block_puzzle_mobile/core/config/remote_config_reader.dart';
import 'package:block_puzzle_mobile/core/di/di_container.dart';
import 'package:block_puzzle_mobile/features/store/application/store_availability.dart';
import 'package:block_puzzle_mobile/features/store/presentation/store_gate.dart';
import 'package:block_puzzle_mobile/features/store/presentation/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() async {
    await sl.reset();
  });

  Widget buildSubject({required Widget child}) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('StoreGate', () {
    testWidgets('renders StoreUnavailableScreen when StoreAvailability is not registered',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildSubject(
          child: const StoreGate(
            child: Text('Secret Store Content'),
          ),
        ),
      );

      expect(find.text('Secret Store Content'), findsNothing);
      expect(find.text('Store is unavailable'), findsOneWidget);
      expect(
        find.textContaining('Monetization is deferred until Stage C'),
        findsOneWidget,
      );
    });

    testWidgets('renders StoreUnavailableScreen when StoreAvailability is disabled (v1.0 default)',
        (WidgetTester tester) async {
      sl.registerSingleton<StoreAvailability>(
        const StoreAvailability(RemoteConfigReader(<String, Object?>{
          'iap.store_enabled': false,
        })),
      );

      await tester.pumpWidget(
        buildSubject(
          child: const StoreGate(
            child: Text('Secret Store Content'),
          ),
        ),
      );

      expect(find.text('Secret Store Content'), findsNothing);
      expect(find.text('Store is unavailable'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('renders child when StoreAvailability is enabled (Stage C)',
        (WidgetTester tester) async {
      sl.registerSingleton<StoreAvailability>(
        const StoreAvailability(RemoteConfigReader(<String, Object?>{
          'iap.store_enabled': true,
        })),
      );

      await tester.pumpWidget(
        buildSubject(
          child: const StoreGate(
            child: Text('Secret Store Content'),
          ),
        ),
      );

      expect(find.text('Secret Store Content'), findsOneWidget);
      expect(find.text('Store is unavailable'), findsNothing);
    });

    testWidgets('StoreScreen directly rendered returns StoreUnavailableScreen when store disabled',
        (WidgetTester tester) async {
      sl.registerSingleton<StoreAvailability>(
        const StoreAvailability(RemoteConfigReader(<String, Object?>{
          'iap.store_enabled': false,
        })),
      );

      await tester.pumpWidget(
        buildSubject(
          child: const StoreScreen(),
        ),
      );

      expect(find.text('Store is unavailable'), findsOneWidget);
      expect(
        find.textContaining('Monetization is deferred until Stage C'),
        findsOneWidget,
      );
      // No store products or price tags are displayed
      expect(find.textContaining('\$'), findsNothing);
      expect(find.text('Neon Skin Pack'), findsNothing);
      expect(find.text('Mono Elegance'), findsNothing);
    });
  });
}
