import 'dart:async';

import 'package:bb_block/core/services/ads/admob_ads_service.dart';
import 'package:bb_block/core/services/ads/ads_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adsServiceProvider = Provider<AdsService>((ref) {
  final service = AdMobAdsService();
  unawaited(service.init());
  return service;
});
