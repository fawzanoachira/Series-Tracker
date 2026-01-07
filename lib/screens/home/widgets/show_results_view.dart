import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/search.dart';
import 'package:series_tracker/screens/home/home_layout.dart';
import 'package:series_tracker/screens/home/widgets/show_grid_tile.dart';
import 'package:series_tracker/screens/home/widgets/show_tile.dart';

class ShowResultsView extends StatelessWidget {
  final List<Search> results;
  final HomeLayout layout;

  const ShowResultsView({
    super.key,
    required this.results,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    if (layout == HomeLayout.grid) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 16,
              children: results.map((search) {
                return SizedBox(
                  width: (480 - (12 * 2)) / 3,
                  child: ShowGridTile(search: search),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    // List view (unchanged)
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ShowTile(search: results[index]);
      },
    );
  }
}
