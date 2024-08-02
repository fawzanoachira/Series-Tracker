import 'package:flutter/material.dart';
import 'package:laebun_va_lahv/api/tracker.dart';
import 'package:laebun_va_lahv/models/search.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController search = TextEditingController();

  List<Search> searchResults = [];
  searchShows() async {
    // await searchShow(name: "The Boys");
    searchResults = await searchShow(name: search.text);
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
            child: Column(children: [
          ...searchResults.map((e) => ListTile(
              onTap: () {},
              title: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Image(
                            image: e.show!.image != null
                                ? NetworkImage("${e.show!.image?.medium}")
                                : const AssetImage(
                                    'assets/images/no_image.jpg'),
                            // errorBuilder: (context, error, stackTrace) =>
                            //     const Text("No Image"),
                            height: 140,
                            width: 100,
                            fit: BoxFit.contain),
                        const SizedBox(width: 20),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(e.show!.name ?? ""),
                              Text("Genre: ${e.show!.genres}"),
                              Text("Average runtime: ${e.show!.averageRuntime}")
                            ])
                      ]),
                    ]),
              )))
        ])
            // bottomNavigationBar: const BottomAppBarData(),
            ));
  }
}
