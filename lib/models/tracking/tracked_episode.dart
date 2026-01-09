class TrackedEpisode {
  final int? id;
  final int showId;
  final int season;
  final int episode;
  final bool watched;
  final DateTime? watchedAt;

  const TrackedEpisode({
    this.id,
    required this.showId,
    required this.season,
    required this.episode,
    required this.watched,
    required this.watchedAt,
  });

  factory TrackedEpisode.fromMap(Map<String, dynamic> map) {
    return TrackedEpisode(
      id: map['id'] as int?,
      showId: map['show_id'] as int,
      season: map['season'] as int,
      episode: map['episode'] as int,
      watched: (map['watched'] as int) == 1,
      watchedAt: map['watched_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['watched_at'] as int,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'show_id': showId,
      'season': season,
      'episode': episode,
      'watched': watched ? 1 : 0,
      'watched_at': watchedAt?.millisecondsSinceEpoch,
    };
  }

  TrackedEpisode copyWith({
    bool? watched,
    DateTime? watchedAt,
  }) {
    return TrackedEpisode(
      id: id,
      showId: showId,
      season: season,
      episode: episode,
      watched: watched ?? this.watched,
      watchedAt: watchedAt ?? this.watchedAt,
    );
  }
}
