import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/search.dart';

class ShowGridTile extends StatelessWidget {
  final Search search;

  const ShowGridTile({super.key, required this.search});

  @override
  Widget build(BuildContext context) {
    final show = search.show;
    final imageUrl = show?.image?.medium;

    return InkWell(
      onTap: () {
        // TODO: navigate to details
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 👈 important
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4, // 👈 poster-like ratio
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Icon(Icons.tv, size: 36),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            show?.name ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
