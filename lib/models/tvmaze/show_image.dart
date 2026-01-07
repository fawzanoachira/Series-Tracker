class ShowImage {
  final String type;
  final String url;

  ShowImage({required this.type, required this.url});

  factory ShowImage.fromJson(Map<String, dynamic> json) {
    return ShowImage(
      type: json['type'] ?? 'unknown',
      url: json['resolutions']['original']['url'],
    );
  }

  static List<ShowImage> listFromJson(List<dynamic> list) {
    return list.map((e) => ShowImage.fromJson(e)).toList();
  }
}
