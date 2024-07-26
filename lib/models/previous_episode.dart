class Previousepisode {
  String? href;
  String? name;

  Previousepisode({this.href, this.name});

  Previousepisode.fromJson(Map<String, dynamic> json) {
    href = json['href'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['href'] = href;
    data['name'] = name;
    return data;
  }

  static List<Previousepisode> listFromJson(List<dynamic> list) {
    List<Previousepisode> rows = list.map((i) => Previousepisode.fromJson(i)).toList();
    return rows;
  }
}
