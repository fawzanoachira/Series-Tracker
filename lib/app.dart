import 'package:flutter/material.dart';
import 'package:laebun_va_lahv/config/color/color.dart';
import 'package:laebun_va_lahv/screens/home/home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laebun va Lahv',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
          appBarTheme: AppBarTheme(color: appBarColor),
          scaffoldBackgroundColor: scaffoldColor,
          iconButtonTheme: IconButtonThemeData(
              style: ButtonStyle(iconColor: WidgetStatePropertyAll(iconColor))),
          bottomAppBarTheme: BottomAppBarTheme(color: appBarColor)),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
