import 'package:flutter/material.dart';
import 'package:lahv/api/tracker.dart';
import 'package:lahv/models/tvmaze/search.dart';
import 'package:lahv/screens/search_screen/search_screen_layout.dart';
import 'package:lahv/screens/search_screen/widgets/home_app_bar.dart';
import 'package:lahv/screens/search_screen/widgets/show_results_view.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  SearchScreenLayout layout = SearchScreenLayout.grid; // Hobi-style default

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
        layout: layout,
        onToggleLayout: () {
          setState(() {
            layout = layout == SearchScreenLayout.grid
                ? SearchScreenLayout.list
                : SearchScreenLayout.grid;
          });
        },
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
        child: Text("Search for a TV series"),
      );
    }

    return ShowResultsView(
      results: searchResults,
      layout: layout,
    );
  }
}
