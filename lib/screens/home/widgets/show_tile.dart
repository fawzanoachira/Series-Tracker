import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/search.dart';

class ShowTile extends StatelessWidget {
  final Search search;

  const ShowTile({super.key, required this.search});

  @override
  Widget build(BuildContext context) {
    final show = search.show;
    final imageUrl = show?.image?.medium;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: const Color.fromARGB(255, 34, 34, 34),
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: navigate to details
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          height: 120,
                          width: 85,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 120,
                          width: 85,
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Icon(Icons.tv, size: 32),
                        ),
                ),
                const SizedBox(width: 14),

                /// Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Title
                      Text(
                        show?.name ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      /// Meta row
                      Row(
                        children: [
                          if (show?.rating?.average != null) ...[
                            const Icon(Icons.star,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              show!.rating!.average.toString(),
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            '${show?.averageRuntime ?? '--'} min',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      /// Genres
                      if (show?.genres?.isNotEmpty == true)
                        Text(
                          show!.genres!.join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
