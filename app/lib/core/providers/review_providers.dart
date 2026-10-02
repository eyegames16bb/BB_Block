import 'package:bb_block/core/services/review/review_service.dart';
import 'package:bb_block/core/services/review/review_service_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reviewServiceProvider = Provider<ReviewService>(
  (ref) => ReviewServiceImpl(),
);
