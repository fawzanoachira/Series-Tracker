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
                    // Show Name with Season Badge if new season
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            upcomingEpisode.showName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (upcomingEpisode.isNewSeason) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 10,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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

              // Air Date Badge with Days Left
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
    final daysUntil = upcomingEpisode.daysUntilAir;

    Color badgeColor;
    Color textColor;

    if (upcomingEpisode.isToday) {
      badgeColor = Colors.green;
      textColor = Colors.white;
    } else if (upcomingEpisode.isPast) {
      badgeColor = Colors.orange;
      textColor = Colors.white;
    } else if (daysUntil == 1) {
      badgeColor = Colors.blue;
      textColor = Colors.white;
    } else {
      badgeColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Days left text
          Text(
            upcomingEpisode.daysLeftText,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          // Air time if available
          if (upcomingEpisode.airTime != null) ...[
            const SizedBox(height: 3),
            Text(
              upcomingEpisode.airTime!,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],

          // Exact date
          if (upcomingEpisode.airDate != null) ...[
            const SizedBox(height: 2),
            Text(
              '${upcomingEpisode.airDate!.month.toString().padLeft(2, '0')}/'
              '${upcomingEpisode.airDate!.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.75),
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
