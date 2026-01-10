import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/models/tracking/tracked_show.dart';
import 'package:series_tracker/models/tvmaze/image_tvmaze.dart';
import 'package:series_tracker/models/tvmaze/show.dart';
import 'package:series_tracker/providers/episode_progress_provider.dart';
import 'package:series_tracker/providers/next_episode_provider.dart';
import 'package:series_tracker/screens/show_detail_screen/show_detail_screen.dart';

class TrackedShowListTile extends ConsumerWidget {
  final TrackedShow show;

  const TrackedShowListTile({super.key, required this.show});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(episodeProgressProvider(show.showId));
    final nextAsync = ref.watch(nextEpisodeProvider(show.showId));

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: show.posterUrl != null
            ? Image.network(
                show.posterUrl!,
                width: 50,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.tv),
      ),
      title: Text(show.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          progressAsync.when(
            data: (episodes) => Text('${episodes.length} episodes watched'),
            loading: () => const Text('Loading progress…'),
            error: (_, __) => const Text('Progress unavailable'),
          ),
          nextAsync.when(
            data: (next) => next == null
                ? const SizedBox.shrink()
                : Text('Up next: S${next.season}E${next.episode}'),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      onTap: () {
        final showModel = Show(
          id: show.showId,
          name: show.name,
          image: show.posterUrl != null
              ? ImageTvmaze(medium: show.posterUrl!)
              : null,
          summary: '',
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShowDetailScreen(show: showModel),
          ),
        );
      },
    );
  }
}
