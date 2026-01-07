import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class ShowSummary extends StatelessWidget {
  final String? summary;

  const ShowSummary({super.key, this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Html(data: summary),
    );
  }
}
