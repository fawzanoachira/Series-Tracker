import 'package:series_tracker/utils/my_cache_manager.dart';

Future<void> preloadImageUrl(String url) async {
  await MyCacheManager.instance.downloadFile(url);
}
