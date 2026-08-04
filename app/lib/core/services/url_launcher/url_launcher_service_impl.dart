import 'package:bb_block/core/services/url_launcher/url_launcher_service.dart';
import 'package:url_launcher/url_launcher.dart' as pkg;

class UrlLauncherServiceImpl implements UrlLauncherService {
  @override
  Future<bool> launch(String url) =>
      pkg.launchUrl(Uri.parse(url), mode: pkg.LaunchMode.externalApplication);
}
