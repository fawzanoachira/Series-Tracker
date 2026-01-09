import 'package:flutter/material.dart';
import 'package:series_tracker/config/color/color.dart';
import 'package:series_tracker/screens/search_screen/search_screen.dart';
import 'package:series_tracker/screens/search_screen/search_screen_view.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laebun va Lahv',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
          appBarTheme: AppBarTheme(backgroundColor: appBarColor),
          // scaffoldBackgroundColor: scaffoldColor,
          iconButtonTheme: IconButtonThemeData(
              style: ButtonStyle(iconColor: WidgetStatePropertyAll(iconColor))),
          bottomAppBarTheme: BottomAppBarThemeData(color: appBarColor)),
      debugShowCheckedModeBanner: false,
      home: const SearchScreen(),
    );
  }
}
