enum TrackedShowStatus {
  watching,
  completed,
  dropped,
}

class TrackedShow {
  final int showId;
  final String name;
  final String? posterUrl;
  final TrackedShowStatus status;
  final DateTime addedAt;

  const TrackedShow({
    required this.showId,
    required this.name,
    required this.posterUrl,
    required this.status,
    required this.addedAt,
  });

  /// Convert DB row → Model
  factory TrackedShow.fromMap(Map<String, dynamic> map) {
    return TrackedShow(
      showId: map['show_id'] as int,
      name: map['name'] as String,
      posterUrl: map['poster_url'] as String?,
      status: TrackedShowStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        map['added_at'] as int,
      ),
    );
  }

  /// Convert Model → DB row
  Map<String, dynamic> toMap() {
    return {
      'show_id': showId,
      'name': name,
      'poster_url': posterUrl,
      'status': status.name,
      'added_at': addedAt.millisecondsSinceEpoch,
    };
  }

  TrackedShow copyWith({
    TrackedShowStatus? status,
  }) {
    return TrackedShow(
      showId: showId,
      name: name,
      posterUrl: posterUrl,
      status: status ?? this.status,
      addedAt: addedAt,
    );
  }
}
