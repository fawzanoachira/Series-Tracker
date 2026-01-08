import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/show.dart';
import 'package:series_tracker/screens/show_detail/widgets/show_header.dart';
import 'package:series_tracker/screens/show_detail/widgets/show_metadata_row.dart';
import 'package:series_tracker/screens/show_detail/widgets/show_primary_info.dart';
import 'package:series_tracker/screens/show_detail/widgets/show_seasons_progress.dart';
import 'package:series_tracker/screens/show_detail/widgets/show_tags_row.dart';

class ShowDetailView extends StatelessWidget {
  final Show show;

  const ShowDetailView({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        ShowHeader(show: show),
        SliverToBoxAdapter(child: ShowPrimaryInfo(show: show)),
        SliverToBoxAdapter(child: ShowMetadataRow(show: show)),
        SliverToBoxAdapter(child: ShowTagsRow(tags: show.genres ?? [])),
        SliverToBoxAdapter(child: ShowSeasonsProgress(showId: show.id!)),
      ],
    );
  }
}
