import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:lahv/api/api.dart';
import 'package:lahv/models/tvmaze/episode.dart';
import 'package:lahv/models/tvmaze/search.dart';
import 'package:lahv/models/tvmaze/season.dart';
import 'package:lahv/models/tvmaze/show.dart';
import 'package:lahv/models/tvmaze/show_image.dart';

final dio = Dio(baseOptions);

Future<List<Search>> searchShow({required String name}) async {
  try {
    final response = await dio.get("/search/shows?q=$name");
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

Future<List<Season>> getSeasons(int showId) async {
  try {
    final response = await dio.get('/shows/$showId/seasons');
    log(response.data.toString());
    return Season.listFromJson(response.data);
  } catch (e) {
    log(e.toString());
    return [];
  }
}

Future<List<Episode>> getEpisodes(int seasonId) async {
  try {
    final response = await dio.get('/seasons/$seasonId/episodes');
    log(response.data.toString());
    return Episode.listFromJson(response.data);
  } catch (e) {
    log(e.toString());
    return [];
  }
}

Future<Show> getShow(int showId) async {
  try {
    final response = await dio.get('/shows/$showId');
    log(response.data.toString());
    return Show.fromJson(response.data);
  } catch (e) {
    rethrow;
  }
}
