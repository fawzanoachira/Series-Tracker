import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:series_tracker/api/tracker.dart';
import 'package:series_tracker/models/tvmaze/show.dart';
import 'package:series_tracker/models/tvmaze/show_image.dart';
import 'package:series_tracker/utils/my_cache_manager.dart';
import 'package:series_tracker/utils/show_image_picker.dart';

class ShowHeader extends StatelessWidget {
  final Show show;
  final String? backgroundImageUrl;

  const ShowHeader({
    super.key,
    required this.show,
    this.backgroundImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(show.name ?? ''),
        background: FutureBuilder<List<ShowImage>>(
          future: fetchShowImages(show.id!),
          builder: (context, snapshot) {
            final images = snapshot.data ?? [];
            final picked = pickBestShowImage(images);
            final bgImage = picked?.url ?? show.image?.original;

            if (bgImage == null) {
              return Container(color: Colors.black);
            }

            return CachedNetworkImage(
              cacheManager: MyCacheManager.instance,
              imageUrl: bgImage,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.black26,
                child: const Center(child: Icon(Icons.error)),
              ),
            );
          },
        ),
      ),
    );
  }
}
