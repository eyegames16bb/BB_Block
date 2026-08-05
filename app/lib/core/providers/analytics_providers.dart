import 'package:bb_block/core/services/analytics/analytics_service.dart';
import 'package:bb_block/core/services/analytics/supabase_analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => SupabaseAnalyticsService(),
);
