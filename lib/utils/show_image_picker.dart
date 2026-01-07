import 'package:series_tracker/models/tvmaze/show_image.dart';

ShowImage? pickBestShowImage(List<ShowImage> images) {
  if (images.isEmpty) return null;

  // Priority order
  final background = images.where((i) => i.type == 'background');
  if (background.isNotEmpty) return background.first;

  final banner = images.where((i) => i.type == 'banner');
  if (banner.isNotEmpty) return banner.first;

  final poster = images.where((i) => i.type == 'poster');
  if (poster.isNotEmpty) return poster.first;

  return images.first;
}
