import 'package:flutter/material.dart';
import 'package:lahv/models/tvmaze/show.dart';
import 'package:lahv/screens/show_detail_screen/widgets/show_actions.dart';
import 'package:lahv/screens/show_detail_screen/widgets/show_header.dart';
import 'package:lahv/screens/show_detail_screen/widgets/show_info.dart';
import 'package:lahv/screens/show_detail_screen/widgets/show_seasons_section.dart';
import 'package:lahv/screens/show_detail_screen/widgets/show_summary.dart';

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
