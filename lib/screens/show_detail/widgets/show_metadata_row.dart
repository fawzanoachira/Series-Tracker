import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/show.dart';

class ShowMetadataRow extends StatelessWidget {
  final Show show;

  const ShowMetadataRow({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MetaItem(Icons.star, '${show.rating?.average ?? '-'}'),
          _MetaItem(Icons.movie, show.genres?.first ?? '-'),
          _MetaItem(Icons.timer, '${show.runtime ?? '-'}m'),
          _MetaItem(Icons.tv, show.network?.name ?? '-'),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String value;

  const _MetaItem(this.icon, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurpleAccent),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
