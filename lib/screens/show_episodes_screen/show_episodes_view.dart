import 'package:flutter/material.dart';
import 'package:lahv/models/tvmaze/season.dart';
import 'package:lahv/screens/show_episodes_screen/widgets/episodes_list_screen.dart';

class ShowEpisodesView extends StatelessWidget {
  final int showId;
  final Season season;

  const ShowEpisodesView(
      {super.key, required this.season, required this.showId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EpisodesListScreen(
        season: season,
        showId: showId,
      ),
    );
  }
}
