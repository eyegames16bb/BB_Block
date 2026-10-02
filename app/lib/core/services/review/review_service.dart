abstract interface class ReviewService {
  /// Requests the platform's own native "rate this app" prompt — Google
  /// Play's in-app review sheet on Android, `SKStoreReviewController` on
  /// iOS (user instruction: a real OS-level prompt, not a custom 5-star
  /// screen built into the app). The OS itself decides whether to actually
  /// show it (both platforms throttle how often a real prompt can appear
  /// per install, independent of how many times this is called) — this
  /// only ever *requests* it, never forces it, matching how every other
  /// app using this same native API behaves.
  Future<void> requestReview();
}
