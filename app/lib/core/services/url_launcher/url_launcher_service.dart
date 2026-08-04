abstract interface class UrlLauncherService {
  /// Opens [url] in an external browser/app. Returns whether the platform
  /// reported success.
  Future<bool> launch(String url);
}
