import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/models/tracking/upcoming_episode.dart';
import 'package:series_tracker/models/tvmaze/image_tvmaze.dart';
import 'package:series_tracker/models/tvmaze/show.dart';
import 'package:series_tracker/screens/show_detail_screen/show_detail_screen.dart';

class UpcomingEpisodeCard extends ConsumerWidget {
  final UpcomingEpisode upcomingEpisode;

  const UpcomingEpisodeCard({
    super.key,
    required this.upcomingEpisode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episode = upcomingEpisode.episode;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final showModel = Show(
            id: upcomingEpisode.showId,
            name: upcomingEpisode.showName,
            image: upcomingEpisode.posterUrl != null
                ? ImageTvmaze(medium: upcomingEpisode.posterUrl!)
                : null,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShowDetailScreen(show: showModel),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Show Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: upcomingEpisode.posterUrl != null
                    ? Image.network(
                        upcomingEpisode.posterUrl!,
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),

              // Episode Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show Name
                    Text(
                      upcomingEpisode.showName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Episode Identifier (S01E01)
                    Text(
                      upcomingEpisode.episodeIdentifier,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Episode Name
                    if (episode.name != null)
                      Text(
                        episode.name!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Air Date Badge
              _buildAirDateBadge(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 90,
      color: Colors.grey[850],
      child: const Icon(Icons.tv, size: 32, color: Colors.grey),
    );
  }

  Widget _buildAirDateBadge(BuildContext context) {
    final theme = Theme.of(context);
    Color badgeColor;
    Color textColor;

    if (upcomingEpisode.isToday) {
      badgeColor = Colors.green;
      textColor = Colors.white;
    } else if (upcomingEpisode.isPast) {
      badgeColor = Colors.orange;
      textColor = Colors.white;
    } else {
      badgeColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            upcomingEpisode.formattedAirDate,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (upcomingEpisode.airTime != null)
            Text(
              upcomingEpisode.airTime!,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}
