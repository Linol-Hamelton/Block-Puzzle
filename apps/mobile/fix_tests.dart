import 'dart:io';

void main() {
  final file = File('test/unit/features/game_loop/game_loop_controller_test.dart');
  var content = file.readAsStringSync();

  // Add the imports we need for the new services
  if (!content.contains('package:block_puzzle_mobile/data/repositories/in_memory_game_session_repository.dart')) {
    content = content.replaceFirst(
      "import 'package:flutter_test/flutter_test.dart';",
      "import 'package:flutter_test/flutter_test.dart';\n"
      "import 'package:block_puzzle_mobile/data/repositories/in_memory_game_session_repository.dart';\n"
      "import 'package:block_puzzle_mobile/features/game_loop/application/services/services.dart';\n",
    );
  }

  // Define our controller builder helper at the end of the file if not present
  if (!content.contains('_buildController')) {
    content += '''

GameLoopController _buildController({
  required RemoteConfigRepository remoteConfigRepository,
  required AnalyticsTracker analyticsTracker,
  required AdService adService,
  required AdGuardrailPolicy adGuardrailPolicy,
  required IapStoreService iapStoreService,
  required PlayerProgressRepository playerProgressRepository,
  required AppLogger logger,
  DateTime Function()? nowUtcProvider,
}) {
  return GameLoopController(
    placePieceUseCase: const PlacePieceUseCase(moveValidator: BasicMoveValidator()),
    clearLinesUseCase: const ClearLinesUseCase(lineClearService: BasicLineClearService()),
    computeScoreUseCase: const ComputeScoreUseCase(scoreService: BasicScoreService()),
    pieceGenerationService: _SingleCellPieceGenerationService(),
    difficultyTuner: const _DefaultDifficultyTuner(),
    remoteConfigRepository: remoteConfigRepository,
    analyticsTracker: analyticsTracker,
    adService: adService,
    adGuardrailPolicy: adGuardrailPolicy,
    iapStoreService: iapStoreService,
    logger: logger,
    gameSessionRepository: InMemoryGameSessionRepository(),
    progressionSyncService: ProgressionSyncService(
      playerProgressRepository: playerProgressRepository,
      analyticsTracker: analyticsTracker,
      logger: logger,
      nowUtcProvider: nowUtcProvider,
    ),
    abExperimentService: ABExperimentService(
      remoteConfigRepository: remoteConfigRepository,
      analyticsTracker: analyticsTracker,
      logger: logger,
    ),
    shareFlowService: ShareFlowService(analyticsTracker: analyticsTracker),
    onboardingFlowController: OnboardingFlowController(
      playerProgressRepository: playerProgressRepository,
      analyticsTracker: analyticsTracker,
      logger: logger,
    ),
    nowUtcProvider: nowUtcProvider,
  );
}
''';
  }

  // Now replace all GameLoopController instantiations with _buildController
  // The instantiations are multiline, so we can replace "GameLoopController(" with "_buildController("
  // But wait, the arguments for _buildController don't need placePieceUseCase, clearLinesUseCase, etc.
  // Actually, a simpler regex is just to match the whole block.
  
  final regex = RegExp(
    r'GameLoopController\(\s+placePieceUseCase:.*?\n\s+clearLinesUseCase:.*?\n\s+computeScoreUseCase:.*?\n\s+pieceGenerationService:.*?\n\s+difficultyTuner:.*?\n\s+remoteConfigRepository:\s*(.*?),\n\s+analyticsTracker:\s*(.*?),\n\s+adService:\s*(.*?),\n\s+adGuardrailPolicy:\s*(.*?),\n\s+iapStoreService:\s*(.*?),\n\s+playerProgressRepository:\s*(.*?),\n\s+logger:\s*(.*?),(?:\n\s+nowUtcProvider:\s*(.*?),)?\n\s+\)',
    multiLine: true,
  );

  content = content.replaceAllMapped(regex, (match) {
    final remoteConfig = match.group(1);
    final analytics = match.group(2);
    final adService = match.group(3);
    final adGuardrail = match.group(4);
    final iapStore = match.group(5);
    final progress = match.group(6);
    final logger = match.group(7);
    final nowUtc = match.group(8);

    var res = '_buildController(\n'
        '  remoteConfigRepository: $remoteConfig,\n'
        '  analyticsTracker: $analytics,\n'
        '  adService: $adService,\n'
        '  adGuardrailPolicy: $adGuardrail,\n'
        '  iapStoreService: $iapStore,\n'
        '  playerProgressRepository: $progress,\n'
        '  logger: $logger,\n';
    if (nowUtc != null) {
      res += '  nowUtcProvider: $nowUtc,\n';
    }
    res += ')';
    return res;
  });

  file.writeAsStringSync(content);
  print('Updated game_loop_controller_test.dart successfully!');
}
