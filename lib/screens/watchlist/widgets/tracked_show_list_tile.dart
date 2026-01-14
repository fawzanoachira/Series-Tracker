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
    final watchedAsync = ref.watch(episodeProgressProvider(show.showId));
    final nextAsync = ref.watch(nextEpisodeProvider(show.showId));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
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
            /// Poster
            SizedBox(
              width: 86,
              height: 120,
              child: Image.network(
                show.posterUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderPoster(),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: watchedAsync.when(
                  data: (watchedEpisodes) {
                    if (watchedEpisodes.isEmpty) {
                      return _emptyProgress(theme, colorScheme);
                    }

                    /// Assume last item is latest watched
                    final lastWatched = watchedEpisodes.last;
                    final watchedCount = watchedEpisodes.length;

                    return nextAsync.when(
                      data: (next) {
                        final totalEpisodes =
                            next == null ? watchedCount : watchedCount + 1;
                        final progress =
                            watchedCount / totalEpisodes.clamp(1, 999);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Title
                            Text(
                              show.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 6),

                            /// Last watched episode
                            Text(
                              'S${lastWatched.season} • '
                              'E${lastWatched.episode}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 8),

                            /// Custom mould progress bar
                            _MouldProgressBar(
                              progress: progress,
                              colorScheme: colorScheme,
                            ),

                            const SizedBox(height: 10),

                            /// Up next
                            if (next != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.play_circle_outline_rounded,
                                    size: 18,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Up next: S${next.season} • '
                                      'E${next.episode}',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
                      loading: () => _loading(theme, colorScheme),
                      error: (_, __) => _error(theme, colorScheme),
                    );
                  },
                  loading: () => _loading(theme, colorScheme),
                  error: (_, __) => _error(theme, colorScheme),
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
      child: const Icon(Icons.tv_rounded, color: Colors.white54),
    );
  }

  Widget _loading(ThemeData theme, ColorScheme scheme) {
    return Text(
      'Loading progress…',
      style:
          theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
  }

  Widget _error(ThemeData theme, ColorScheme scheme) {
    return Text(
      'Progress unavailable',
      style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
    );
  }

  Widget _emptyProgress(ThemeData theme, ColorScheme scheme) {
    return Text(
      'No episodes watched yet',
      style:
          theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}

/// 🔥 Custom mould-style progress bar
class _MouldProgressBar extends StatelessWidget {
  final double progress;
  final ColorScheme colorScheme;

  const _MouldProgressBar({
    required this.progress,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
