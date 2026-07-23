abstract interface class AdsService {
  Future<void> init();

  bool get isRewardedAdReady;

  Future<void> showRewardedAd({required void Function() onRewardEarned});
}
