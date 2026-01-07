import 'package:flutter/material.dart';
import 'package:series_tracker/api/tracker.dart';
import 'package:series_tracker/models/tvmaze/search.dart';
import 'package:series_tracker/screens/home/widgets/home_app_bar.dart';
import 'package:series_tracker/screens/home/widgets/show_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Search> searchResults = [];
  bool isLoading = false;

  Future<void> searchShows() async {
    if (searchController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
    });

    final results = await searchShow(name: searchController.text.trim());

    if (!mounted) return;

    setState(() {
      searchResults = results;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        searchController: searchController,
        onSearch: searchShows,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchResults.isEmpty) {
      return const Center(
        child: Text(
          "Search for a TV series",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        return ShowTile(search: searchResults[index]);
      },
    );
  }
}
