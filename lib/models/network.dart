import 'package:series_tracker/models/country.dart';

class Network {
  int? id;
  String? name;
  Country? country;
  String? officialSite;

  Network({this.id, this.name, this.country, this.officialSite});

  Network.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    country =
        json['country'] != null ? Country.fromJson(json['country']) : null;
    officialSite = json['officialSite'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    if (country != null) {
      data['country'] = country!.toJson();
    }
    data['officialSite'] = officialSite;
    return data;
  }

  static List<Network> listFromJson(List<dynamic> list) {
    List<Network> rows = list.map((i) => Network.fromJson(i)).toList();
    return rows;
  }
}