import 'package:flutter/material.dart';
import 'package:series_tracker/api/tracker.dart';
import 'package:series_tracker/models/tvmaze/season.dart';
import 'package:series_tracker/screens/show_detail/widgets/show_progress_tile.dart';

class ShowSeasonsProgress extends StatelessWidget {
  final int showId;

  const ShowSeasonsProgress({super.key, required this.showId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Season>>(
      future: getSeasons(showId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        return Column(
          children: snapshot.data!
              .map((season) => SeasonProgressTile(season: season))
              .toList(),
        );
      },
    );
  }
}
