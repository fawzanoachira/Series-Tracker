import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/api/tracker.dart';
import 'package:lahv/models/tvmaze/season.dart';
import 'package:lahv/screens/show_detail_screen/widgets/show_season_row.dart';

// Cached provider for seasons - won't rebuild unless explicitly invalidated
final showSeasonsProvider =
    FutureProvider.family<List<Season>, int>((ref, showId) async {
  return getSeasons(showId);
});

class ShowSeasonsSection extends ConsumerWidget {
  final int showId;

  const ShowSeasonsSection({super.key, required this.showId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonsAsync = ref.watch(showSeasonsProvider(showId));

    return seasonsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
      data: (seasons) {
        if (seasons.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Seasons',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ShowSeasonRow(
              seasons: seasons,
              showId: showId,
            ),
          ],
        );
      },
    );
  }
}
