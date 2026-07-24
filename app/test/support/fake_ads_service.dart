import 'package:bb_block/core/services/ads/ads_service.dart';

/// Defaults to never ready, so tests exercise the "ad not loaded yet" path
/// instead of touching `google_mobile_ads`'s platform channel, which isn't
/// available under `flutter test`. Pass `isRewardedAdReady: true` to
/// exercise the reward-granting path instead.
class FakeAdsService implements AdsService {
  FakeAdsService({this.isRewardedAdReady = false});

  @override
  final bool isRewardedAdReady;

  int rewardCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> showRewardedAd({
    required void Function() onRewardEarned,
  }) async {
    rewardCalls++;
    if (isRewardedAdReady) onRewardEarned();
  }
}
