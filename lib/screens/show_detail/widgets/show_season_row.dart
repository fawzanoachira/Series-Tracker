import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/season.dart';
import 'package:series_tracker/screens/show_detail/widgets/show_episodes_screen.dart';

class ShowSeasonRow extends StatelessWidget {
  final List<Season> seasons;

  const ShowSeasonRow({super.key, required this.seasons});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: seasons.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final season = seasons[index];

        return ListTile(
          title: Text('Season ${season.number}'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShowEpisodesScreen(season: season),
              ),
            );
          },
        );
      },
    );
  }
}
