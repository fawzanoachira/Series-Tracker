import 'package:flutter/material.dart';
import 'package:series_tracker/api/tracker.dart';
import 'package:series_tracker/models/tvmaze/season.dart';
import 'package:series_tracker/screens/show_detail_screen/widgets/show_season_row.dart';

class ShowSeasonsSection extends StatelessWidget {
  final int showId;

  const ShowSeasonsSection({super.key, required this.showId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Season>>(
      future: getSeasons(showId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            // padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Seasons',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ShowSeasonRow(
              seasons: snapshot.data!,
              showId: showId,
            ),
          ],
        );
      },
    );
  }
}
