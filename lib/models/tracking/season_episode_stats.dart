class SeasonEpisodeStats {
  final int season;
  final int watched;
  final int total;
  final bool isLoading;
  final bool hasError;

  SeasonEpisodeStats({
    required this.season,
    required this.watched,
    required this.total,
    this.isLoading = false,
    this.hasError = false,
  });

  factory SeasonEpisodeStats.loading() =>
      SeasonEpisodeStats(season: 0, watched: 0, total: 0, isLoading: true);

  factory SeasonEpisodeStats.error() =>
      SeasonEpisodeStats(season: 0, watched: 0, total: 0, hasError: true);

  double get progress => total == 0 ? 0 : watched / total;

  bool get isComplete => watched == total;
}
