import 'package:flutter/material.dart';
import 'package:series_tracker/api/tracker.dart';
import 'package:series_tracker/models/tvmaze/episode.dart';
import 'package:series_tracker/models/tvmaze/season.dart';
import 'package:series_tracker/screens/show_episodes/widgets/episode_carousel_sheet.dart';

class EpisodesListScreen extends StatelessWidget {
  final Season season;

  const EpisodesListScreen({super.key, required this.season});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Season ${season.number}'),
      ),
      body: FutureBuilder<List<Episode>>(
        future: getEpisodes(season.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final episodes = snapshot.data!;
            return ListView.separated(
              itemCount: episodes.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final ep = episodes[index];
                return ListTile(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => EpisodeCarouselSheet(
                        episodes: episodes, // all episodes of that season
                        initialIndex: index, // the one that was tapped
                        // showImages: showImages, // pass show banner images
                      ),
                    );
                  },
                  title: Text(ep.name ?? 'Episode ${ep.number}'),
                  subtitle: Text(ep.airdate ?? ''),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                );
              },
            );
          }
        },
      ),
    );
  }
}
