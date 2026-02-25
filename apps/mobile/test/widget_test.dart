import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/app/block_puzzle_app.dart';

void main() {
  testWidgets('App shows start button', (WidgetTester tester) async {
    await tester.pumpWidget(const BlockPuzzleApp());
    expect(find.text('Start Classic'), findsOneWidget);
  });
}
