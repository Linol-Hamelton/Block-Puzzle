import '../../core/logging/app_logger.dart';
import 'ad_placement.dart';
import 'ad_service.dart';
import 'ad_show_result.dart';

class DebugAdService implements AdService {
  DebugAdService({
    required this.logger,
  });

  final AppLogger logger;

  @override
  Future<void> preload() async {
    logger.info('DebugAdService preload completed');
  }

  @override
  Future<AdShowResult> showBanner({
    required AdPlacement placement,
  }) async {
    logger.info('Show banner: ${placement.wireName}');
    return AdShowResult.shown(
      network: 'debug_network',
      ecpmUsd: 0.35,
    );
  }

  @override
  Future<AdShowResult> showInterstitial({
    required AdPlacement placement,
  }) async {
    logger.info('Show interstitial: ${placement.wireName}');
    return AdShowResult.shown(
      network: 'debug_network',
      ecpmUsd: 1.45,
    );
  }

  @override
  Future<AdShowResult> showRewarded({
    required AdPlacement placement,
    required String rewardType,
    required int rewardValue,
  }) async {
    logger.info(
      'Show rewarded: ${placement.wireName} '
      'rewardType=$rewardType rewardValue=$rewardValue',
    );
    return AdShowResult.shown(
      network: 'debug_network',
      ecpmUsd: 2.1,
      rewardGranted: true,
    );
  }
}
