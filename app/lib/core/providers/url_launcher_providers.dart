import 'package:bb_block/core/services/url_launcher/url_launcher_service.dart';
import 'package:bb_block/core/services/url_launcher/url_launcher_service_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final urlLauncherServiceProvider = Provider<UrlLauncherService>(
  (ref) => UrlLauncherServiceImpl(),
);
