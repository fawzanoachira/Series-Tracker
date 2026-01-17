import 'package:flutter/material.dart';
import 'package:lahv/models/tvmaze/episode.dart';
import 'package:lahv/models/tvmaze/show_image.dart';
import 'package:lahv/screens/show_episodes_screen/widgets/episode_detail_sheet.dart';

class EpisodeCarouselSheet extends StatefulWidget {
  final int showId;
  final List<Episode> episodes;
  final int initialIndex;
  final List<ShowImage>? showImages;

  const EpisodeCarouselSheet({
    super.key,
    required this.showId,
    required this.episodes,
    required this.initialIndex,
    this.showImages,
  });

  @override
  State<EpisodeCarouselSheet> createState() => _EpisodeCarouselSheetState();
}

class _EpisodeCarouselSheetState extends State<EpisodeCarouselSheet> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
  }

  void _previous() {
    if (_currentIndex > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _next() {
    if (_currentIndex < widget.episodes.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.episodes.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final episode = widget.episodes[index];
              return Hero(
                tag: 'episode_${episode.id}',
                child: EpisodeDetailSheet(
                  episode: episode,
                  showId: widget.showId,
                  showImages: widget.showImages,
                ),
              );
            },
          ),
          if (_currentIndex > 0)
            Positioned(
              left: 4,
              top: 180,
              child: IconButton(
                icon: const Icon(Icons.chevron_left, size: 32),
                onPressed: _previous,
              ),
            ),
          if (_currentIndex < widget.episodes.length - 1)
            Positioned(
              right: 4,
              top: 180,
              child: IconButton(
                icon: const Icon(Icons.chevron_right, size: 32),
                onPressed: _next,
              ),
            ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _dots(context),
                const SizedBox(height: 4),
                Text(
                  '${_currentIndex + 1} / ${widget.episodes.length}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dots(BuildContext context) {
    const maxDots = 7;
    final total = widget.episodes.length;

    int start = _currentIndex - maxDots ~/ 2;
    int end = _currentIndex + maxDots ~/ 2;

    if (start < 0) {
      start = 0;
      end = maxDots - 1;
    }

    if (end > total - 1) {
      end = total - 1;
      start = (end - maxDots + 1).clamp(0, total - 1);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(end - start + 1, (i) {
        final index = start + i;
        final active = index == _currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 12 : 8,
          height: active ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade500,
          ),
        );
      }),
    );
  }
}
