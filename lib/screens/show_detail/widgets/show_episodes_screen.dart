import 'package:flutter/material.dart';
import 'package:series_tracker/api/tracker.dart';
import 'package:series_tracker/models/tvmaze/episode.dart';
import 'package:series_tracker/models/tvmaze/season.dart';

class ShowEpisodesScreen extends StatelessWidget {
  final Season season;

  const ShowEpisodesScreen({super.key, required this.season});

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
