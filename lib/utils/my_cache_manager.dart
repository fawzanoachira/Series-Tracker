import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class MyCacheManager {
  static const key = 'customCacheManager';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(seconds: 10),
      maxNrOfCacheObjects: 1,
    ),
  );
}
