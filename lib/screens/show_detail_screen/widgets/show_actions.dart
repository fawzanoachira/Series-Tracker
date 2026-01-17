import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/models/tvmaze/show.dart';
import 'package:lahv/providers/is_show_tracked_provider.dart';
import 'package:lahv/providers/tracking_actions_provider.dart';

class ShowActions extends ConsumerWidget {
  final Show show;

  const ShowActions({super.key, required this.show});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showId = show.id!;

    final isTrackedAsync = ref.watch(isShowTrackedProvider(showId));
    final actionState = ref.watch(trackingActionsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: isTrackedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (isTracked) {
          return Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: actionState.isLoading
                      ? null
                      : () {
                          final actions =
                              ref.read(trackingActionsProvider.notifier);

                          if (isTracked) {
                            actions.removeShow(showId);
                          } else {
                            actions.addShow(show);
                          }
                        },
                  child: actionState.isLoading
                      ? const CircularProgressIndicator()
                      : Text(isTracked ? 'Untrack Show' : 'Track Show'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
