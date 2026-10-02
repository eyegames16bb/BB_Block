import 'package:bb_block/core/services/review/review_service.dart';

/// Records how many times the real native review prompt was requested,
/// instead of touching the real `in_app_review` platform channel (which
/// isn't available under `flutter test`).
class FakeReviewService implements ReviewService {
  int requestCount = 0;

  @override
  Future<void> requestReview() async {
    requestCount++;
  }
}
