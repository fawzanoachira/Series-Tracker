class Schedule {
  String? time;
  List<String>? days;

  Schedule({this.time, this.days});

  Schedule.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    days = json['days'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['time'] = time;
    data['days'] = days;
    return data;
  }

  static List<Schedule> listFromJson(List<dynamic> list) {
    List<Schedule> rows = list.map((i) => Schedule.fromJson(i)).toList();
    return rows;
  }
}