import 'package:flutter/material.dart';

class ShowTagsRow extends StatelessWidget {
  final List<String> tags;

  const ShowTagsRow({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => Chip(
          label: Text(tags[i]),
          backgroundColor: Colors.deepPurple.withOpacity(0.2),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: tags.length,
      ),
    );
  }
}
