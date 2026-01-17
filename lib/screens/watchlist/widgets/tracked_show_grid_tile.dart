import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/models/tracking/tracked_show.dart';
import 'package:lahv/models/tvmaze/image_tvmaze.dart';
import 'package:lahv/models/tvmaze/show.dart';
import 'package:lahv/providers/next_episode_provider.dart';
import 'package:lahv/providers/show_progress_provider.dart';
import 'package:lahv/screens/show_detail_screen/show_detail_screen.dart';
import 'package:lahv/widgets/cached_image.dart';

class TrackedShowGridTile extends ConsumerWidget {
  final TrackedShow show;

  const TrackedShowGridTile({super.key, required this.show});

  void _navigateToShowDetail(BuildContext context) {
    final showModel = Show(
      id: show.showId,
      name: show.name,
      image:
          show.posterUrl != null ? ImageTvmaze(medium: show.posterUrl!) : null,
      summary: '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShowDetailScreen(show: showModel),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(showProgressProvider(show.showId));
    final nextAsync = ref.watch(nextEpisodeProvider(show.showId));

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _navigateToShowDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: show.posterUrl != null
                  ? CachedImage(url: show.posterUrl!)
                  : Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.tv,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                        size: 40,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),

          // Title
          Text(
            show.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),

          // Progress count
          progressAsync.when(
            data: (progress) {
              return Text(
                '${progress.watchedCount}/${progress.totalCount} watched',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              );
            },
            loading: () => Text(
              'Loading...',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
            ),
            error: (_, __) => Text(
              'Error loading progress',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
            ),
          ),
          const SizedBox(height: 2),

          // Up next / Completed status
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
                'Up next: S${next.season.toString().padLeft(2, '0')}'
                'E${next.episode.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              );
            },
            loading: () => const SizedBox(height: 16),
            error: (_, __) => Text(
              'Error loading next episode',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
