// Currently Not Using...


import 'package:flutter/material.dart';
import 'package:series_tracker/api/tracker.dart';
import 'package:series_tracker/models/tvmaze/episode.dart';
import 'package:series_tracker/models/tvmaze/season.dart';

class ShowSeasons extends StatefulWidget {
  final int showId;

  const ShowSeasons({super.key, required this.showId});

  @override
  State<ShowSeasons> createState() => _ShowSeasonsState();
}

class _ShowSeasonsState extends State<ShowSeasons>
    with TickerProviderStateMixin {
  late Future<List<Season>> seasonsFuture;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    seasonsFuture = getSeasons(widget.showId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Season>>(
      future: seasonsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final seasons = snapshot.data!;
          _tabController ??= TabController(length: seasons.length, vsync: this);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Seasons', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: seasons
                    .map((s) => Tab(text: 'Season ${s.number}'))
                    .toList(),
              ),
              SizedBox(
                height: 400, // adjust as needed
                child: TabBarView(
                  controller: _tabController,
                  children: seasons.map((season) {
                    return FutureBuilder<List<Episode>>(
                      future: getEpisodes(season.id!),
                      builder: (context, epSnapshot) {
                        if (epSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (epSnapshot.hasError) {
                          return Center(
                              child: Text('Error: ${epSnapshot.error}'));
                        } else {
                          final episodes = epSnapshot.data!;
                          return ListView.builder(
                            itemCount: episodes.length,
                            itemBuilder: (context, index) {
                              final ep = episodes[index];
                              return ListTile(
                                title: Text(ep.name ?? 'Episode ${ep.number}'),
                                subtitle: Text(ep.airdate ?? ''),
                              );
                            },
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
