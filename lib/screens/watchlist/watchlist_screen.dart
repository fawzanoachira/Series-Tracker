import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lahv/providers/tracked_shows_provider.dart';
import 'package:lahv/models/tracking/tracked_show.dart';
import 'widgets/tracked_show_grid_tile.dart';
import 'widgets/tracked_show_list_tile.dart';

enum WatchlistView { grid, list }

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  WatchlistView _view = WatchlistView.list;

  @override
  Widget build(BuildContext context) {
    final trackedShowsAsync = ref.watch(trackedShowsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Lahv",
          key: const ValueKey('title'),
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            // You can customize further: color, etc.
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _view == WatchlistView.grid ? Icons.view_list : Icons.grid_view,
            ),
            onPressed: () {
              setState(() {
                _view = _view == WatchlistView.grid
                    ? WatchlistView.list
                    : WatchlistView.grid;
              });
            },
          ),
        ],
      ),
      body: trackedShowsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (shows) {
          // Filter to only show "watching" status
          final watchingShows = shows
              .where((show) => show.status == TrackedShowStatus.watching)
              .toList();

          if (watchingShows.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(trackedShowsProvider);
                await ref.read(trackedShowsProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: const Center(
                    child: Text('No shows in watchlist'),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(trackedShowsProvider);
              await ref.read(trackedShowsProvider.future);
            },
            child: _view == WatchlistView.grid
                ? _WatchlistGrid(shows: watchingShows)
                : _WatchlistList(shows: watchingShows),
          );
        },
      ),
    );
  }
}

class _WatchlistGrid extends StatelessWidget {
  final List<TrackedShow> shows;
  const _WatchlistGrid({required this.shows});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: shows.length,
      itemBuilder: (_, index) {
        return TrackedShowGridTile(show: shows[index]);
      },
    );
  }
}

class _WatchlistList extends StatelessWidget {
  final List<TrackedShow> shows;
  const _WatchlistList({required this.shows});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: shows.length,
      itemBuilder: (_, index) {
        return TrackedShowListTile(show: shows[index]);
      },
    );
  }
}
