class Episode {
  int? id;
  int? season;
  int? number;
  String? name;
  String? airdate;
  String? airtime;
  String? runtime;
  String? summary;

  Episode({
    this.id,
    this.season,
    this.number,
    this.name,
    this.airdate,
    this.airtime,
    this.runtime,
    this.summary,
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
    return data;
  }

  static List<Episode> listFromJson(List<dynamic> list) {
    return list.map((i) => Episode.fromJson(i)).toList();
  }
}
