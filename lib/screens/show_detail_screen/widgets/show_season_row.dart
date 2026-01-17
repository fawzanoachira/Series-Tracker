import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/api/tracker.dart' as tracker;
import 'package:lahv/models/tvmaze/season.dart';
import 'package:lahv/providers/core_providers.dart';
import 'package:lahv/providers/episode_tracking_revision_provider.dart';
import 'package:lahv/providers/tracked_shows_provider.dart';
import 'package:lahv/providers/episode_progress_provider.dart';
import 'package:lahv/screens/show_episodes_screen/show_episodes_view.dart';

class ShowSeasonRow extends ConsumerWidget {
  final int showId;
  final List<Season> seasons;

  const ShowSeasonRow({
    super.key,
    required this.seasons,
    required this.showId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: seasons.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final season = seasons[index];

        return _SeasonListTile(
          showId: showId,
          season: season,
        );
      },
    );
  }
}

class _SeasonListTile extends ConsumerStatefulWidget {
  final int showId;
  final Season season;

  const _SeasonListTile({
    required this.showId,
    required this.season,
  });

  @override
  ConsumerState<_SeasonListTile> createState() => _SeasonListTileState();
}

class _SeasonListTileState extends ConsumerState<_SeasonListTile> {
  bool? _optimisticWatched;
  bool _isLoading = false;

  Future<bool> _isSeasonFullyWatched() async {
    try {
      final episodes = await tracker.getEpisodes(widget.season.id!);
      final watchedEpisodes =
          await ref.read(episodeProgressProvider(widget.showId).future);

      if (episodes.isEmpty) return false;

      final watchedSet =
          watchedEpisodes.map((e) => '${e.season}-${e.episode}').toSet();

      return episodes.every((ep) {
        final key = '${ep.season ?? 0}-${ep.number ?? 0}';
        return watchedSet.contains(key);
      });
    } catch (e) {
      return false;
    }
  }

  Future<void> _toggleSeasonWatched() async {
    if (_isLoading) return;

    try {
      // Fetch all episodes for this season
      final episodes = await tracker.getEpisodes(widget.season.id!);

      if (episodes.isEmpty) return;

      // Check if season is fully watched
      final isFullyWatched = await _isSeasonFullyWatched();

      // Optimistically update UI
      setState(() {
        _optimisticWatched = !isFullyWatched;
        _isLoading = true;
      });

      // Prepare episodes list for batch operation
      final episodesList = episodes
          .map((ep) => (season: ep.season ?? 0, episode: ep.number ?? 0))
          .toList();

      final repo = ref.read(trackingRepositoryProvider);

      if (isFullyWatched) {
        // Batch unmark all episodes
        await repo.markMultipleEpisodesUnwatched(
          showId: widget.showId,
          episodes: episodesList,
        );
      } else {
        // Batch mark all episodes as watched
        await repo.markMultipleEpisodesWatched(
          showId: widget.showId,
          episodes: episodesList,
        );
      }

      // Trigger UI refresh for THIS show only
      ref.read(episodeTrackingRevisionProvider(widget.showId).notifier).state++;

      // Check show completion status and only refresh if status changed
      final statusChanged =
          await repo.checkAndUpdateShowCompletion(widget.showId);
      if (statusChanged) {
        ref.invalidate(trackedShowsProvider);
      }

      // Clear optimistic state after completion
      if (mounted) {
        setState(() {
          _optimisticWatched = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticWatched = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the episode progress to reactively update when episodes change
    final watchedEpisodesAsync =
        ref.watch(episodeProgressProvider(widget.showId));

    return ListTile(
      title: Text('Season ${widget.season.number}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          watchedEpisodesAsync.when(
            loading: () => const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => const SizedBox(width: 48),
            data: (watchedEpisodes) {
              return FutureBuilder(
                future: tracker.getEpisodes(widget.season.id!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(width: 48);
                  }

                  final episodes = snapshot.data!;

                  // Calculate if season is fully watched
                  final watchedSet = watchedEpisodes
                      .map((e) => '${e.season}-${e.episode}')
                      .toSet();

                  final actualWatched = episodes.isNotEmpty &&
                      episodes.every((ep) {
                        final season = ep.season ?? 0;
                        final number = ep.number ?? 0;
                        final key = '$season-$number';
                        return watchedSet.contains(key);
                      });

                  // Use optimistic state if available, otherwise use actual state
                  final isFullyWatched = _optimisticWatched ?? actualWatched;

                  return IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isFullyWatched
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            color: isFullyWatched ? Colors.green : Colors.grey,
                          ),
                    tooltip: isFullyWatched
                        ? 'Mark season as unwatched'
                        : 'Mark season as watched',
                    onPressed: _isLoading ? null : _toggleSeasonWatched,
                  );
                },
              );
            },
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShowEpisodesView(
              season: widget.season,
              showId: widget.showId,
            ),
          ),
        );
      },
    );
  }
}
