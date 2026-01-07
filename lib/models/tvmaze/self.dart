class Self {
  String? href;

  Self({this.href});

  Self.fromJson(Map<String, dynamic> json) {
    href = json['href'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['href'] = href;
    return data;
  }

  static List<Self> listFromJson(List<dynamic> list) {
    List<Self> rows = list.map((i) => Self.fromJson(i)).toList();
    return rows;
  }
}
