import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/show.dart';
import 'package:series_tracker/screens/show_detail/widgets/show_actions.dart';
import 'package:series_tracker/screens/show_detail/widgets/show_header.dart';
import 'package:series_tracker/screens/show_detail/widgets/show_info.dart';
import 'package:series_tracker/screens/show_detail/widgets/show_seasons_section.dart';
import 'package:series_tracker/screens/show_detail/widgets/show_summary.dart';

class ShowDetailView extends StatelessWidget {
  final Show show;

  const ShowDetailView({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        ShowHeader(show: show),
        SliverToBoxAdapter(child: ShowInfo(show: show)),
        SliverToBoxAdapter(child: ShowSummary(summary: show.summary)),
        SliverToBoxAdapter(child: ShowActions(show: show)),
        SliverToBoxAdapter(child: ShowSeasonsSection(showId: show.id!)),
      ],
    );
  }
}
