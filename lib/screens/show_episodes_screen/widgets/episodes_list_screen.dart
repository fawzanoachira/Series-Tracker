import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/api/tracker.dart';
import 'package:lahv/models/tvmaze/episode.dart';
import 'package:lahv/models/tvmaze/season.dart';
import 'package:lahv/providers/is_episode_watched_provider.dart';
import 'package:lahv/providers/tracking_actions_provider.dart';
import 'package:lahv/providers/has_episode_aired_provider.dart';
import 'package:lahv/screens/show_episodes_screen/widgets/episode_carousel_sheet.dart';

// Provider for fetching episodes (cached per season)
final seasonEpisodesProvider = FutureProvider.family<List<Episode>, int>(
  (ref, seasonId) async {
    return await getEpisodes(seasonId);
  },
);

class EpisodesListScreen extends ConsumerWidget {
  final int showId;
  final Season season;

  const EpisodesListScreen({
    super.key,
    required this.showId,
    required this.season,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(seasonEpisodesProvider(season.id!));

    return Scaffold(
      appBar: AppBar(
        title: Text('Season ${season.number}'),
      ),
      body: episodesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (episodes) {
          return ListView.separated(
            itemCount: episodes.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final ep = episodes[index];
              return _EpisodeListTile(
                showId: showId,
                episode: ep,
                episodes: episodes,
                index: index,
              );
            },
          );
        },
      ),
    );
  }
}

class _EpisodeListTile extends ConsumerStatefulWidget {
  final int showId;
  final Episode episode;
  final List<Episode> episodes;
  final int index;

  const _EpisodeListTile({
    required this.showId,
    required this.episode,
    required this.episodes,
    required this.index,
  });

  @override
  ConsumerState<_EpisodeListTile> createState() => _EpisodeListTileState();
}

class _EpisodeListTileState extends ConsumerState<_EpisodeListTile> {
  bool? _optimisticWatched;

  @override
  Widget build(BuildContext context) {
    final episodeKey = (
      showId: widget.showId,
      season: widget.episode.season ?? 0,
      episode: widget.episode.number ?? 0,
    );
    final actualWatched = ref.watch(isEpisodeWatchedProvider(episodeKey));
    final hasAired = ref.watch(hasEpisodeAiredProvider(widget.episode));

    // Use optimistic state if available, otherwise use actual state
    final isWatched = _optimisticWatched ?? actualWatched;

    // Can always unwatch, but can only watch if aired
    final canInteract = isWatched || hasAired;

    return ListTile(
      onTap: () {
        showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SafeArea(
                    child: EpisodeCarouselSheet(
                  showId: widget.showId,
                  episodes: widget.episodes,
                  initialIndex: widget.index,
                )));
      },
      title: Text(widget.episode.name ?? 'Episode ${widget.episode.number}'),
      subtitle: Text(
        widget.episode.airdate != null
            ? hasAired
                ? widget.episode.airdate!
                : '${widget.episode.airdate!} (Not aired)'
            : 'Unknown air date',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      trailing: IconButton(
        icon: Icon(
          isWatched
              ? Icons.check_circle
              : hasAired
                  ? Icons.add_circle_outline
                  : Icons.schedule,
          color: isWatched
              ? Colors.green
              : hasAired
                  ? Colors.grey
                  : Colors.orange.shade300,
        ),
        onPressed: canInteract
            ? () async {
                // Optimistically update UI immediately
                setState(() {
                  _optimisticWatched = !isWatched;
                });

                final actions = ref.read(trackingActionsProvider.notifier);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  if (isWatched) {
                    await actions.markEpisodeUnwatched(
                      showId: widget.showId,
                      season: widget.episode.season ?? 0,
                      episode: widget.episode.number ?? 0,
                    );
                  } else {
                    await actions.markEpisodeWatched(
                      showId: widget.showId,
                      season: widget.episode.season ?? 0,
                      episode: widget.episode.number ?? 0,
                    );
                  }

                  // Clear optimistic state once actual state is updated
                  if (mounted) {
                    setState(() {
                      _optimisticWatched = null;
                    });
                  }
                } catch (e) {
                  // Revert optimistic update on error
                  if (mounted) {
                    setState(() {
                      _optimisticWatched = null;
                    });
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to update: $e')),
                    );
                  }
                }
              }
            : null,
      ),
    );
  }
}
