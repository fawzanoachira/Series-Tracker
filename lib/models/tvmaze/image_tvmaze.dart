class ImageTvmaze {
  String? medium;
  String? original;

  ImageTvmaze({this.medium, this.original});

  ImageTvmaze.fromJson(Map<String, dynamic> json) {
    medium = json['medium'];
    original = json['original'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['medium'] = medium;
    data['original'] = original;
    return data;
  }

  static List<ImageTvmaze> listFromJson(List<dynamic> list) {
    List<ImageTvmaze> rows = list.map((i) => ImageTvmaze.fromJson(i)).toList();
    return rows;
  }
}
