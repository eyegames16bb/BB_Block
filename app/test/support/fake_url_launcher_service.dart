import 'package:bb_block/core/services/url_launcher/url_launcher_service.dart';

/// Records launched URLs instead of touching `url_launcher`'s platform
/// channel, which isn't available under `flutter test`.
class FakeUrlLauncherService implements UrlLauncherService {
  final List<String> launchedUrls = [];

  @override
  Future<bool> launch(String url) async {
    launchedUrls.add(url);
    return true;
  }
}
