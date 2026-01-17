import 'package:lahv/models/tvmaze/previous_episode.dart';
import 'package:lahv/models/tvmaze/self.dart';

class Links {
  Self? self;
  Previousepisode? previousepisode;

  Links({this.self, this.previousepisode});

  Links.fromJson(Map<String, dynamic> json) {
    self = json['self'] != null ? Self.fromJson(json['self']) : null;
    previousepisode = json['previousepisode'] != null
        ? Previousepisode.fromJson(json['previousepisode'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (self != null) {
      data['self'] = self!.toJson();
    }
    if (previousepisode != null) {
      data['previousepisode'] = previousepisode!.toJson();
    }
    return data;
  }

  static List<Links> listFromJson(List<dynamic> list) {
    List<Links> rows = list.map((i) => Links.fromJson(i)).toList();
    return rows;
  }
}
