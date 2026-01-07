class WebChannel {
  int? id;
  String? name;
  String? country;
  String? officialSite;

  WebChannel({this.id, this.name, this.country, this.officialSite});

  WebChannel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    country = json['country'];
    officialSite = json['officialSite'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['country'] = country;
    data['officialSite'] = officialSite;
    return data;
  }

  static List<WebChannel> listFromJson(List<dynamic> list) {
    List<WebChannel> rows = list.map((i) => WebChannel.fromJson(i)).toList();
    return rows;
  }
}
