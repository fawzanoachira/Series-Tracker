import 'package:flutter/material.dart';
import 'package:lahv/config/color/color.dart';
import 'package:lahv/screens/root/root_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lahv',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: scaffoldColor,
          colorScheme: const ColorScheme.dark(
            primary: primaryColor,
            secondary: secondaryColor,
            surface: appBarColor,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: appBarColor,
            elevation: 0,
          ),
          iconTheme: const IconThemeData(color: iconColor),
          bottomAppBarTheme: const BottomAppBarThemeData(
            color: appBarColor,
          )),
      debugShowCheckedModeBanner: false,
      home: const SafeArea(top: false, child: RootScreen()),
    );
  }
}
