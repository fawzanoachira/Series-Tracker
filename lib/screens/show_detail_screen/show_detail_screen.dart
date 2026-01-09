import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/show.dart';
import 'package:series_tracker/screens/show_detail_screen/show_detail_view.dart';

class ShowDetailScreen extends StatelessWidget {
  final Show show;

  const ShowDetailScreen({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ShowDetailView(show: show),
    );
  }
}
