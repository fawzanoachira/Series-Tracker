import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/season.dart';

class SeasonProgressTile extends StatelessWidget {
  final Season season;

  const SeasonProgressTile({super.key, required this.season});

  @override
  Widget build(BuildContext context) {
    const progress = 0.4; // TODO: from local tracking

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Season ${season.number}'),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade800,
              valueColor: const AlwaysStoppedAnimation(
                Colors.deepPurpleAccent,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '4 / ${season.number ?? '?'} episodes',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
