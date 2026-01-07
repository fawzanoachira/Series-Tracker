import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/show.dart';

class ShowInfo extends StatelessWidget {
  final Show show;

  const ShowInfo({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Genres: ${show.genres?.join(', ') ?? '-'}"),
          const SizedBox(height: 8),
          Text("Language: ${show.language ?? '-'}"),
          const SizedBox(height: 8),
          Text("Rating: ${show.rating?.average ?? 'N/A'}"),
          const SizedBox(height: 8),
          Text("Status: ${show.status ?? '-'}"),
        ],
      ),
    );
  }
}
