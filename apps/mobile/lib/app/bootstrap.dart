import 'package:flutter/widgets.dart';

import 'block_puzzle_app.dart';
import '../core/di/di_container.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const BlockPuzzleApp());
}
