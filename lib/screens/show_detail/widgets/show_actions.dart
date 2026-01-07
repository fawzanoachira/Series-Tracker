import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/show.dart';

class ShowActions extends StatelessWidget {
  final Show show;

  const ShowActions({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // save to local storage (Hive / SharedPreferences)
              },
              child: const Text("Track Show"),
            ),
          ),
        ],
      ),
    );
  }
}
