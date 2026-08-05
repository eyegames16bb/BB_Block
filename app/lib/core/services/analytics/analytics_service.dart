abstract interface class AnalyticsService {
  /// Records that a rewarded ad was watched to completion — feeds the
  /// eyegames.net admin dashboard's ad-view counters.
  Future<void> logRewardedAdView();
}
