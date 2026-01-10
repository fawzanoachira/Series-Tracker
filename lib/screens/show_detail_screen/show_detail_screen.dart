import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/models/tvmaze/show.dart';
import 'package:series_tracker/providers/show_detail_provider.dart';
import 'show_detail_view.dart';

class ShowDetailScreen extends ConsumerWidget {
  final Show show;

  const ShowDetailScreen({super.key, required this.show});

  bool get _hasFullData => show.summary != null && show.summary!.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Case 1: already full (from Search)
    if (_hasFullData) {
      return Scaffold(
        body: ShowDetailView(show: show),
      );
    }

    // Case 2: minimal (from Watchlist)
    final asyncShow = ref.watch(showDetailProvider(show.id!));

    return Scaffold(
      body: asyncShow.when(
        data: (fullShow) => ShowDetailView(show: fullShow),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Failed to load show details'),
        ),
      ),
    );
  }
}
