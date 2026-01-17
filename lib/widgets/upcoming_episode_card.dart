import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/models/tracking/upcoming_episode.dart';
import 'package:lahv/models/tvmaze/image_tvmaze.dart';
import 'package:lahv/models/tvmaze/show.dart';
import 'package:lahv/screens/show_detail_screen/show_detail_screen.dart';

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
    final imageUrl = episode.image?.medium ?? upcomingEpisode.posterUrl;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
              // Episode/Show Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 70,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 16),

              // Episode Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show Name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            upcomingEpisode.showName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Episode Identifier (S01E01)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            upcomingEpisode.episodeIdentifier,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (upcomingEpisode.isNewSeason) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.star_rate_rounded,
                                  size: 20,
                                  color: Color.fromARGB(255, 255, 196, 0),
                                )
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Episode Name
                    if (episode.name != null && episode.name!.isNotEmpty)
                      Text(
                        episode.name!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[300],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              const SizedBox(width: 12),

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
      width: 70,
      height: 100,
      color: Colors.grey[850],
      child: const Icon(Icons.tv, size: 36, color: Colors.grey),
    );
  }

  Widget _buildAirDateBadge(BuildContext context) {
    final theme = Theme.of(context);
    final daysUntil = upcomingEpisode.daysUntilAir;

    Color badgeColor;
    Color textColor;

    if (upcomingEpisode.isToday) {
      badgeColor = Colors.green[700]!;
      textColor = Colors.white;
    } else if (upcomingEpisode.isPast) {
      badgeColor = Colors.orange[700]!;
      textColor = Colors.white;
    } else if (daysUntil == 1) {
      badgeColor = Colors.blue[700]!;
      textColor = Colors.white;
    } else {
      badgeColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          // Air time if available
          if (upcomingEpisode.airTime != null) ...[
            const SizedBox(height: 4),
            Text(
              upcomingEpisode.airTime!,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.9),
                fontSize: 11,
              ),
            ),
          ],

          // Exact date
          if (upcomingEpisode.airDate != null) ...[
            const SizedBox(height: 4),
            Text(
              '${upcomingEpisode.airDate!.month.toString().padLeft(2, '0')}/'
              '${upcomingEpisode.airDate!.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
