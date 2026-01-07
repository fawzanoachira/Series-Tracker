import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final VoidCallback onSearch;

  const HomeAppBar({
    super.key,
    required this.searchController,
    required this.onSearch,
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
        const SizedBox(width: 12),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
