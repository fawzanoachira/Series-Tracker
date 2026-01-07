class Season {
  int? id;
  int? number;
  String? name;
  String? premiereDate;
  String? endDate;
  String? network;
  String? summary;

  Season({
    this.id,
    this.number,
    this.name,
    this.premiereDate,
    this.endDate,
    this.network,
    this.summary,
  });

  Season.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    number = json['number'];
    name = json['name'];
    premiereDate = json['premiereDate'];
    endDate = json['endDate'];
    network = json['network']?['name'];
    summary = json['summary'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['number'] = number;
    data['name'] = name;
    data['premiereDate'] = premiereDate;
    data['endDate'] = endDate;
    data['network'] = network;
    data['summary'] = summary;
    return data;
  }

  static List<Season> listFromJson(List<dynamic> list) {
    return list.map((i) => Season.fromJson(i)).toList();
  }
}
