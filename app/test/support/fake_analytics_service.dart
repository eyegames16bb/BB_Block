import 'package:bb_block/core/services/analytics/analytics_service.dart';

/// Records calls instead of touching Supabase, which isn't reachable under
/// `flutter test`.
class FakeAnalyticsService implements AnalyticsService {
  int rewardedAdViewCount = 0;

  @override
  Future<void> logRewardedAdView() async {
    rewardedAdViewCount++;
  }
}
