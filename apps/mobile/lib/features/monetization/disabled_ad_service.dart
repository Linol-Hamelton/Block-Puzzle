import 'ad_placement.dart';
import 'ad_service.dart';
import 'ad_show_result.dart';

class DisabledAdService implements AdService {
  const DisabledAdService();

  @override
  Future<void> preload() async {}

  @override
  Future<AdShowResult> showBanner({
    required AdPlacement placement,
  }) async {
    return AdShowResult.unavailable(
      network: 'ad_free_mode',
      reason: 'ad_free_mode',
    );
  }

  @override
  Future<AdShowResult> showInterstitial({
    required AdPlacement placement,
  }) async {
    return AdShowResult.unavailable(
      network: 'ad_free_mode',
      reason: 'ad_free_mode',
    );
  }

  @override
  Future<AdShowResult> showRewarded({
    required AdPlacement placement,
    required String rewardType,
    required int rewardValue,
  }) async {
    return AdShowResult.unavailable(
      network: 'ad_free_mode',
      reason: 'ad_free_mode',
    );
  }
}
