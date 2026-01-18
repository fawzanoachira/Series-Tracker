import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/screens/analytics/analytics_screen.dart';
import 'package:lahv/screens/search_screen/search_screen.dart';
import 'package:lahv/navigation/bottom_app_bar.dart';
import 'package:lahv/screens/watchlist/watchlist_screen.dart';
import 'package:lahv/screens/my_shows/my_shows_screen.dart';
import 'package:lahv/providers/auth_provider.dart';

class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  int _currentIndex = 0; // Watchlist default

  late final List<Widget> _screens = [
    const WatchlistScreen(),
    const MyShowsScreen(), // All tracked shows (watching, completed, dropped)
    const SearchScreen(), // Discovery
    const AnalyticsScreen(),
  ];

  final List<String> _screenTitles = [
    'Watchlist',
    'My Shows',
    'Discover',
    'Analytics',
  ];

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _showAccountMenu() async {
    final user = ref.read(currentUserProvider);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Signed in as:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'Unknown',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.tonalIcon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authService = ref.read(authServiceProvider);
        await authService.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signed out successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: _showAccountMenu,
            tooltip: 'Account',
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomAppBarData(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
