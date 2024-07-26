import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:laebun_va_lahv/api/api.dart';
import 'package:laebun_va_lahv/models/search.dart';

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

// searchShowTest() async {
//   try {
//     final response = await dio.get("/search/shows?q=boys");
//     log(response.toString());
//   } catch (e) {
//     log(e.toString());
//     return [];
//   }
// }
