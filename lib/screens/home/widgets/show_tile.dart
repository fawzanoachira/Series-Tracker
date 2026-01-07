import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/search.dart';

class ShowTile extends StatelessWidget {
  final Search search;

  const ShowTile({super.key, required this.search});

  @override
  Widget build(BuildContext context) {
    final show = search.show;
    final imageUrl = show?.image?.medium;

    return ListTile(
      onTap: () {
        // TODO: Navigate to details / add to tracker
      },
      contentPadding: const EdgeInsets.all(8),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image(
            image: imageUrl != null
                ? NetworkImage(imageUrl)
                : const AssetImage('assets/images/no_image.jpg')
                    as ImageProvider,
            height: 140,
            width: 100,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  show?.name ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Genres: ${show?.genres?.join(', ') ?? 'N/A'}",
                ),
                const SizedBox(height: 4),
                Text(
                  "Average runtime: ${show?.averageRuntime ?? 'N/A'} min",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
