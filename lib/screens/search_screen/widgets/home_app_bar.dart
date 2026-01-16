import 'package:flutter/material.dart';
import 'package:series_tracker/screens/search_screen/search_screen_layout.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
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
  State<HomeAppBar> createState() => _HomeAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeAppBarState extends State<HomeAppBar> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: _isSearching
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                });
                widget.searchController.clear();
                // Optionally, trigger a reset or refresh if needed via a callback
              },
            )
          : null,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _isSearching
            ? TextField(
                key: const ValueKey('search_field'),
                controller: widget.searchController,
                autofocus: true,
                onSubmitted: (_) => widget.onSearch(),
                decoration: const InputDecoration(
                  hintText: "Search shows...",
                  border: InputBorder.none,
                ),
              )
            : Text(
                "Lahv",
                key: const ValueKey('title'),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  // You can customize further: color, etc.
                ),
              ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            if (_isSearching) {
              widget.onSearch();
            } else {
              setState(() {
                _isSearching = true;
              });
            }
          },
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          icon: Icon(
            widget.layout == SearchScreenLayout.grid
                ? Icons.view_list
                : Icons.grid_view,
          ),
          onPressed: widget.onToggleLayout,
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
