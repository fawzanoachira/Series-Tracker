import 'package:flutter/material.dart';
import 'package:series_tracker/screens/search_screen/search_screen_layout.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final SearchScreenLayout layout;
  final VoidCallback onToggleLayout;

  const HomeAppBar({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.layout,
    required this.onToggleLayout,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Image.asset(
        "assets/images/lahv_logo.png",
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      ),
      actions: [
        SizedBox(
          width: 220,
          child: TextField(
            controller: searchController,
            onSubmitted: (_) => onSearch(),
            decoration: const InputDecoration(
              hintText: "Search TV shows...",
              border: InputBorder.none,
            ),
          ),
        ),
        IconButton(
          onPressed: onSearch,
          icon: const Icon(Icons.search_rounded),
        ),

        // 👇 THIS IS THE TOGGLE BUTTON
        IconButton(
          icon: Icon(
            layout == SearchScreenLayout.grid ? Icons.view_list : Icons.grid_view,
          ),
          onPressed: onToggleLayout,
        ),

        const SizedBox(width: 12),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
