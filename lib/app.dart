import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/config/color/color.dart';
import 'package:lahv/providers/auth_provider.dart';
import 'package:lahv/screens/auth/login_screen.dart';
import 'package:lahv/screens/root/root_screen.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Lahv',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: scaffoldColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          // secondary: secondColor,
          surface: appBarColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: appBarColor,
          elevation: 0,
        ),
        iconTheme: const IconThemeData(color: iconColor),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: appBarColor,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: ref.watch(authStateProvider).when(
            data: (user) {
              // If user is logged in, show root screen
              // If not logged in, show login screen
              return user != null
                  ? const SafeArea(top: false, child: RootScreen())
                  : const LoginScreen();
            },
            loading: () => const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Authentication Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Retry by invalidating the auth state
                        ref.invalidate(authStateProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
