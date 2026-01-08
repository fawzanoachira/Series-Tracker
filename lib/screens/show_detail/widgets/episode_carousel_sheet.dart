import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/episode.dart';
import 'package:series_tracker/models/tvmaze/show_image.dart';
import 'package:series_tracker/screens/show_detail/widgets/episode_detail_sheet.dart';

class EpisodeCarouselSheet extends StatefulWidget {
  final List<Episode> episodes;
  final int initialIndex;
  final List<ShowImage>? showImages;

  const EpisodeCarouselSheet({
    super.key,
    required this.episodes,
    required this.initialIndex,
    this.showImages,
  });

  @override
  State<EpisodeCarouselSheet> createState() => _EpisodeCarouselSheetState();
}

class _EpisodeCarouselSheetState extends State<EpisodeCarouselSheet> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400, // fixed height for bottom sheet
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.episodes.length,
        itemBuilder: (context, index) {
          return EpisodeDetailSheet(
            episode: widget.episodes[index],
            showImages: widget.showImages,
          );
        },
      ),
    );
  }
}
