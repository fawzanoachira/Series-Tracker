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

  const TrackedShowListTile({
    super.key,
    required this.show,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(episodeProgressProvider(show.showId));
    final nextAsync = ref.watch(nextEpisodeProvider(show.showId));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1.5,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster + subtle overlay gradient
            SizedBox(
              width: 86,
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  show.posterUrl != null
                      ? Image.network(
                          show.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderPoster(),
                        )
                      : _placeholderPoster(),
                  // Optional subtle gradient overlay (looks modern)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title – bold + better typography
                    Text(
                      show.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Progress row
                    progressAsync.when(
                      data: (watchedEpisodes) {
                        final count = watchedEpisodes.length;
                        // You could also get total episodes from show model if available
                        // For now we just show watched count
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '$count episodes watched',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Tiny progress chip (optional – looks nice)
                                if (count > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Optional: tiny progress bar (uncomment if useful)
                            // ClipRRect(
                            //   borderRadius: BorderRadius.circular(4),
                            //   child: LinearProgressIndicator(
                            //     value: count / 24, // replace with real total
                            //     minHeight: 4,
                            //     backgroundColor: colorScheme.surfaceVariant,
                            //   ),
                            // ),
                          ],
                        );
                      },
                      loading: () => Text(
                        'Loading progress…',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      error: (_, __) => Text(
                        'Progress unavailable',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Next episode – more prominent when available
                    nextAsync.when(
                      data: (next) {
                        if (next == null) return const SizedBox.shrink();

                        return Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Up next: S${next.season} • E${next.episode}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderPoster() {
    return Container(
      color: Colors.grey.shade800,
      child: const Icon(
        Icons.tv_rounded,
        size: 36,
        color: Colors.white54,
      ),
    );
  }
}
