import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/show.dart';

class ShowPrimaryInfo extends StatelessWidget {
  final Show show;

  const ShowPrimaryInfo({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  show.name ?? '',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  show.status ?? '',
                  style: const TextStyle(color: Colors.greenAccent),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
            ),
            onPressed: () {},
            child: const Text('Watched'),
          ),
        ],
      ),
    );
  }
}
