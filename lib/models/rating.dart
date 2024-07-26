class Rating {
  double? average;

  Rating({this.average});

  Rating.fromJson(Map<String, dynamic> json) {
    average = json['average'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['average'] = average;
    return data;
  }

  static List<Rating> listFromJson(List<dynamic> list) {
    List<Rating> rows = list.map((i) => Rating.fromJson(i)).toList();
    return rows;
  }
}