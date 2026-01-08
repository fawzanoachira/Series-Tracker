import 'image_tvmaze.dart';

class Episode {
  int? id;
  int? season;
  int? number;
  String? name;
  String? airdate;
  String? airtime;
  String? runtime;
  String? summary;
  ImageTvmaze? image;

  Episode({
    this.id,
    this.season,
    this.number,
    this.name,
    this.airdate,
    this.airtime,
    this.runtime,
    this.summary,
    this.image,
  });

  Episode.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    season = json['season'];
    number = json['number'];
    name = json['name'];
    airdate = json['airdate'];
    airtime = json['airtime'];
    runtime = json['runtime']?.toString();
    summary = json['summary'];
    image =
        json['image'] != null ? ImageTvmaze.fromJson(json['image']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['season'] = season;
    data['number'] = number;
    data['name'] = name;
    data['airdate'] = airdate;
    data['airtime'] = airtime;
    data['runtime'] = runtime;
    data['summary'] = summary;
    if (image != null) {
      data['image'] = image!.toJson();
    }
    return data;
  }

  static List<Episode> listFromJson(List<dynamic> list) {
    return list.map((i) => Episode.fromJson(i)).toList();
  }
}
