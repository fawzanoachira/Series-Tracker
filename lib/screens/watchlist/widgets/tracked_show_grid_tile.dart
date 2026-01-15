import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/models/tracking/tracked_show.dart';
import 'package:series_tracker/models/tvmaze/image_tvmaze.dart';
import 'package:series_tracker/models/tvmaze/show.dart';
import 'package:series_tracker/providers/next_episode_provider.dart';
import 'package:series_tracker/providers/show_progress_provider.dart';
import 'package:series_tracker/screens/show_detail_screen/show_detail_screen.dart';

class TrackedShowGridTile extends ConsumerWidget {
  final TrackedShow show;

  const TrackedShowGridTile({super.key, required this.show});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(showProgressProvider(show.showId));
    final nextAsync = ref.watch(nextEpisodeProvider(show.showId));

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // Create a minimal Show object for navigation
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: show.posterUrl != null
                  ? Image.network(
                      show.posterUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.tv),
                    ),
            ),
          ),

          const SizedBox(height: 6),

          // Title
          Text(
            show.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 4),

          // Progress count
          progressAsync.when(
            data: (progress) {
              return Text(
                '${progress.watchedCount}/${progress.totalCount} watched',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              );
            },
            loading: () => const SizedBox(height: 16),
            error: (_, __) => const SizedBox(height: 16),
          ),

          const SizedBox(height: 2),

          // Up next
          nextAsync.when(
            data: (next) {
              if (next == null) {
                return Text(
                  'All caught up! 🎉',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                );
              }
              return Text(
                'Up next: S${next.season}E${next.episode}',
                style: Theme.of(context).textTheme.labelSmall,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
