import 'package:bb_block/core/services/haptics/haptics_service.dart';
import 'package:bb_block/core/services/haptics/vibration_haptics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hapticsServiceProvider = Provider<HapticsService>(
  (ref) => VibrationHapticsService(),
);
