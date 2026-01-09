import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/season.dart';
import 'package:series_tracker/screens/show_episodes/widgets/episodes_list_screen.dart';

class ShowEpisodesView extends StatelessWidget {
  final Season season;

  const ShowEpisodesView({super.key, required this.season});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EpisodesListScreen(season: season),
    );
  }
}
