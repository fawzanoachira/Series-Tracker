import 'package:flutter/material.dart';
import 'package:series_tracker/screens/search_screen/search_screen.dart';
import 'package:series_tracker/navigation/bottom_app_bar.dart';
import 'package:series_tracker/screens/watchlist/watchlist_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0; // Discovery default

  late final List<Widget> _screens = [
    const WatchlistScreen(),
    const _PlaceholderScreen(title: 'My Shows'),
    const SearchScreen(), // Discovery
    const _PlaceholderScreen(title: 'Analytics'),
  ];

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomAppBarData(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
