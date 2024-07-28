import 'package:laebun_va_lahv/models/show.dart';

class Search {
  double? score;
  Show? show;

  Search({this.score, this.show});

  Search.fromJson(Map<String, dynamic> json) {
    score = json['score'];
    show = json['show'] != null ? Show.fromJson(json['show']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['score'] = score;
    if (show != null) {
      data['show'] = show!.toJson();
    }
    return data;
  }

  static List<Search> listFromJson(List<dynamic> list) {
    List<Search> rows = list.map((i) => Search.fromJson(i)).toList();
    return rows;
  }
}
