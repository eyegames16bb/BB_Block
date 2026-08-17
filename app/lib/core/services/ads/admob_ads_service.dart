import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:bb_block/core/services/ads/ads_service.dart';
import 'package:bb_block/core/utils/app_logger.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Uses Google's public AdMob **test** ad unit IDs by default — safe to ship
/// in development builds, but must be replaced with real ad unit IDs (from
/// the AdMob console) before any store submission.
final class AdMobAdsService implements AdsService {
  AdMobAdsService({
    String? androidRewardedAdUnitId,
    String? iosRewardedAdUnitId,
  })  : _androidRewardedAdUnitId =
            androidRewardedAdUnitId ?? _testAndroidRewardedAdUnitId,
        _iosRewardedAdUnitId = iosRewardedAdUnitId ?? _testIosRewardedAdUnitId;

  static const String _testAndroidRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testIosRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  final String _androidRewardedAdUnitId;
  final String _iosRewardedAdUnitId;

  RewardedAd? _rewardedAd;

  String get _rewardedAdUnitId =>
      Platform.isIOS ? _iosRewardedAdUnitId : _androidRewardedAdUnitId;

  @override
  Future<void> init() async {
    // Same defensive pattern as the other platform-channel-backed services
    // (audio, haptics): a missing/unregistered plugin — e.g. in `flutter
    // test`'s headless environment, which has no real ATT/AdMob platform
    // implementation — must not crash the app. `adsServiceProvider` reads
    // this eagerly on every app start (see `app.dart`), so a real failure
    // here would otherwise be an unhandled async error.
    try {
      // App Store rejection risk otherwise: iOS forbids initializing an ad
      // SDK capable of IDFA-based tracking before the user has answered the
      // ATT prompt. `app_tracking_transparency` is iOS-only — the package's
      // own status/request calls are meaningless on Android, hence the guard.
      if (Platform.isIOS) {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      }
      await MobileAds.instance.initialize();
      unawaited(_loadRewardedAd());
    } on Object catch (error) {
      appLogger.w('Could not initialize ads service: $error');
    }
  }

  @override
  bool get isRewardedAdReady => _rewardedAd != null;

  @override
  Future<void> showRewardedAd({
    required void Function() onRewardEarned,
  }) async {
    final ad = _rewardedAd;
    if (ad == null) {
      unawaited(_loadRewardedAd());
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (dismissedAd) {
        unawaited(dismissedAd.dispose());
        _rewardedAd = null;
        unawaited(_loadRewardedAd());
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        unawaited(failedAd.dispose());
        _rewardedAd = null;
        unawaited(_loadRewardedAd());
      },
    );

    await ad.show(
      onUserEarnedReward: (_, _) => onRewardEarned(),
    );
  }

  Future<void> _loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }
}
