import 'package:series_tracker/models/tvmaze/externals.dart';
import 'package:series_tracker/models/tvmaze/image_tvmaze.dart';
import 'package:series_tracker/models/tvmaze/links.dart';
import 'package:series_tracker/models/tvmaze/network.dart';
import 'package:series_tracker/models/tvmaze/rating.dart';
import 'package:series_tracker/models/tvmaze/schedule.dart';

class Show {
  int? id;
  String? url;
  String? name;
  String? type;
  String? language;
  List<String>? genres;
  String? status;
  int? runtime;
  int? averageRuntime;
  String? premiered;
  String? ended;
  String? officialSite;
  Schedule? schedule;
  Rating? rating;
  int? weight;
  Network? network;
  dynamic webChannel;
  dynamic dvdCountry;
  Externals? externals;
  ImageTvmaze? image;
  String? summary;
  int? updated;
  Links? lLinks;

  Show(
      {this.id,
      this.url,
      this.name,
      this.type,
      this.language,
      this.genres,
      this.status,
      this.runtime,
      this.averageRuntime,
      this.premiered,
      this.ended,
      this.officialSite,
      this.schedule,
      this.rating,
      this.weight,
      this.network,
      this.webChannel,
      this.dvdCountry,
      this.externals,
      this.image,
      this.summary,
      this.updated,
      this.lLinks});

  Show.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    url = json['url'];
    name = json['name'];
    type = json['type'];
    language = json['language'];
    genres = json['genres'].cast<String>();
    status = json['status'];
    runtime = json['runtime'];
    averageRuntime = json['averageRuntime'];
    premiered = json['premiered'];
    ended = json['ended'];
    officialSite = json['officialSite'];
    schedule =
        json['schedule'] != null ? Schedule.fromJson(json['schedule']) : null;
    rating = json['rating'] != null ? Rating.fromJson(json['rating']) : null;
    weight = json['weight'];
    network =
        json['network'] != null ? Network.fromJson(json['network']) : null;
    webChannel = json['webChannel'];
    dvdCountry = json['dvdCountry'];
    externals = json['externals'] != null
        ? Externals.fromJson(json['externals'])
        : null;
    image = json['image'] != null ? ImageTvmaze.fromJson(json['image']) : null;
    summary = json['summary'];
    updated = json['updated'];
    lLinks = json['_links'] != null ? Links.fromJson(json['_links']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['url'] = url;
    data['name'] = name;
    data['type'] = type;
    data['language'] = language;
    data['genres'] = genres;
    data['status'] = status;
    data['runtime'] = runtime;
    data['averageRuntime'] = averageRuntime;
    data['premiered'] = premiered;
    data['ended'] = ended;
    data['officialSite'] = officialSite;
    if (schedule != null) {
      data['schedule'] = schedule!.toJson();
    }
    if (rating != null) {
      data['rating'] = rating!.toJson();
    }
    data['weight'] = weight;
    if (network != null) {
      data['network'] = network!.toJson();
    }
    data['webChannel'] = webChannel;
    data['dvdCountry'] = dvdCountry;
    if (externals != null) {
      data['externals'] = externals!.toJson();
    }
    if (image != null) {
      data['image'] = image!.toJson();
    }
    data['summary'] = summary;
    data['updated'] = updated;
    if (lLinks != null) {
      data['_links'] = lLinks!.toJson();
    }
    return data;
  }

  static List<Show> listFromJson(List<dynamic> list) {
    List<Show> rows = list.map((i) => Show.fromJson(i)).toList();
    return rows;
  }
}
