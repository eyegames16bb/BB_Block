import 'dart:io';

import 'package:bb_block/core/services/analytics/analytics_service.dart';
import 'package:bb_block/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Writes to the `ad_views` table — RLS on that table only allows `anon`
/// inserts (see `eyegames.net/supabase/schema.sql`), so this can never read
/// back or touch anything else. Wrapped in the same "log and move on" style
/// as every other best-effort network/asset call in this app (see
/// `AudioPlayersAudioService`) — a failed analytics write must never affect
/// gameplay.
final class SupabaseAnalyticsService implements AnalyticsService {
  @override
  Future<void> logRewardedAdView() async {
    try {
      await Supabase.instance.client.from('ad_views').insert({
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } on Object catch (error) {
      appLogger.w('Could not log rewarded ad view: $error');
    }
  }
}
