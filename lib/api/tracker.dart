import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:series_tracker/api/api.dart';
import 'package:series_tracker/models/tvmaze/search.dart';
import 'package:series_tracker/models/tvmaze/show_image.dart';

final dio = Dio(baseOptions);

Future<List<Search>> searchShow({required String name}) async {
  try {
    final response = await dio.get("/search/shows?q=$name");
    // log((response.data[0]['show'][0]));
    log(response.data.toString());
    return Search.listFromJson(response.data);
  } catch (e) {
    log(e.toString());
    return [];
  }
}

Future<List<ShowImage>> fetchShowImages(int showId) async {
  try {
    final response = await dio.get('/shows/$showId/images');

    log(response.data.toString());
    return ShowImage.listFromJson(response.data);
  } catch (e) {
    log(e.toString());
    return [];
  }
}
