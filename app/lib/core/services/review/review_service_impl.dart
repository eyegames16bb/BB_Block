import 'package:bb_block/core/services/review/review_service.dart';
import 'package:in_app_review/in_app_review.dart';

class ReviewServiceImpl implements ReviewService {
  @override
  Future<void> requestReview() async {
    // Defensive, same `try/on Object catch` pattern every other service in
    // this codebase uses for a platform call with no `flutter test`
    // platform channel (headless tests, or a device/OS version where the
    // native review API genuinely isn't available) — never crash the
    // round-over/ad-close flow over a rating prompt that was always
    // optional.
    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      }
    } on Object {
      // Silently ignored — see above.
    }
  }
}
