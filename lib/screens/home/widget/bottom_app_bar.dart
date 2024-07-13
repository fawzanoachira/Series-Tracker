import 'package:flutter/material.dart';

class BottomAppBarData extends StatelessWidget {
  const BottomAppBarData({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 70,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.tv_rounded)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.explore)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.slideshow_sharp)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.analytics)),
      ]),
    );
  }
}
