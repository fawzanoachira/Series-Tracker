import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:laebun_va_lahv/api/tracker.dart';
import 'package:laebun_va_lahv/models/search.dart';
import 'package:laebun_va_lahv/screens/home/widget/bottom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController search = TextEditingController();

  List<Search> searchres = [];
  searchShows() async {
    // await searchShow(name: "The Boys");
    searchres = await searchShow(name: search.text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lahv"), actions: [
        SizedBox(width: 200, child: TextField(controller: search)),
        IconButton(
            onPressed: () => searchShows(),
            icon: const Icon(Icons.search_rounded)),
        const SizedBox(width: 20),
      ]),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ...searchres.map((e) => ListTile(
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image(
                          image: NetworkImage("${e.show!.image?.medium}"),
                          // errorBuilder: (context, error, stackTrace) =>
                          //     const Text("No Image"),
                          height: 140,
                          width: 100,
                          fit: BoxFit.contain),
                      Text(e.show!.name ?? ""),
                    ],
                  ),
                ))
          ],
        ),
      ),
      // bottomNavigationBar: const BottomAppBarData(),
    );
  }
}
