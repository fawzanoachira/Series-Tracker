import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/api/tracker.dart' as tracker;
import 'package:lahv/models/tvmaze/episode.dart';
import 'episode_progress_provider.dart';

class NextEpisode {
  final int season;
  final int episode;

  const NextEpisode({
    required this.season,
    required this.episode,
  });
}

final nextEpisodeProvider =
    FutureProvider.family<NextEpisode?, int>((ref, showId) async {
  final episodesAsync = ref.watch(episodeProgressProvider(showId));

  return episodesAsync.when(
    data: (watchedEpisodes) async {
      // Fetch all episodes for this show from the API
      List<Episode> allEpisodes = [];

      try {
        // First get all seasons for the show
        final seasons = await tracker.getSeasons(showId);

        // Then fetch episodes for each season
        for (final season in seasons) {
          if (season.id != null) {
            final seasonEpisodes = await tracker.getEpisodes(season.id!);
            allEpisodes.addAll(seasonEpisodes);
          }
        }
      } catch (e) {
        // If API call fails, fall back to simple logic
        if (watchedEpisodes.isEmpty) {
          return const NextEpisode(season: 1, episode: 1);
        }

        watchedEpisodes.sort((a, b) {
          if (a.season != b.season) return a.season.compareTo(b.season);
          return a.episode.compareTo(b.episode);
        });

        final last = watchedEpisodes.last;
        return NextEpisode(season: last.season, episode: last.episode + 1);
      }

      // Sort all episodes
      allEpisodes.sort((a, b) {
        final aSeason = a.season ?? 0;
        final bSeason = b.season ?? 0;
        final aNumber = a.number ?? 0;
        final bNumber = b.number ?? 0;

        if (aSeason != bSeason) return aSeason.compareTo(bSeason);
        return aNumber.compareTo(bNumber);
      });

      // If no episodes watched, return the first episode
      if (watchedEpisodes.isEmpty) {
        if (allEpisodes.isEmpty) return null;
        final firstEpisode = allEpisodes.first;
        return NextEpisode(
          season: firstEpisode.season ?? 1,
          episode: firstEpisode.number ?? 1,
        );
      }

      // Create a set of watched episodes for quick lookup
      final watchedSet =
          watchedEpisodes.map((e) => '${e.season}-${e.episode}').toSet();

      // Find the first unwatched episode
      for (final episode in allEpisodes) {
        final seasonNum = episode.season ?? 0;
        final episodeNum = episode.number ?? 0;
        final key = '$seasonNum-$episodeNum';

        if (!watchedSet.contains(key)) {
          return NextEpisode(
            season: seasonNum,
            episode: episodeNum,
          );
        }
      }

      // All episodes watched
      return null;
    },
    loading: () => const NextEpisode(season: 1, episode: 1),
    error: (_, __) => const NextEpisode(season: 1, episode: 1),
  );
});
