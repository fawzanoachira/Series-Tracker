import 'package:flutter/material.dart';
import 'package:lahv/screens/analytics/analytics_screen.dart';
import 'package:lahv/screens/search_screen/search_screen.dart';
import 'package:lahv/navigation/bottom_app_bar.dart';
import 'package:lahv/screens/watchlist/watchlist_screen.dart';
import 'package:lahv/screens/my_shows/my_shows_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0; // Watchlist default

  late final List<Widget> _screens = [
    const WatchlistScreen(),
    const MyShowsScreen(), // All tracked shows (watching, completed, dropped)
    const SearchScreen(), // Discovery
    const AnalyticsScreen(),
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
