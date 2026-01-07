class Image {
  String? medium;
  String? original;

  Image({this.medium, this.original});

  Image.fromJson(Map<String, dynamic> json) {
    medium = json['medium'];
    original = json['original'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['medium'] = medium;
    data['original'] = original;
    return data;
  }

  static List<Image> listFromJson(List<dynamic> list) {
    List<Image> rows = list.map((i) => Image.fromJson(i)).toList();
    return rows;
  }
}
