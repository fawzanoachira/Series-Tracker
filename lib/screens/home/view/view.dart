import 'package:flutter/material.dart';
import 'package:laebun_va_lahv/screens/home/widget/bottom_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Laebun va Lahv")),
        body: const Text("Hello"),
        bottomNavigationBar: const BottomAppBarData());
  }
}
