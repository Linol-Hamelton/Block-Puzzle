import 'ad_placement.dart';
import 'ad_show_result.dart';

abstract interface class AdService {
  Future<void> preload();

  Future<AdShowResult> showBanner({
    required AdPlacement placement,
  });

  Future<AdShowResult> showInterstitial({
    required AdPlacement placement,
  });

  Future<AdShowResult> showRewarded({
    required AdPlacement placement,
    required String rewardType,
    required int rewardValue,
  });
}
