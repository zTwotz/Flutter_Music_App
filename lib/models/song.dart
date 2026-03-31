class Song {
  final int id;
  final String title;
  final String? artistName;
  final String? artistId;
  final int? albumId;
  final String? coverUrl;
  final String audioUrl;
  final int durationSeconds;

  Song({
    required this.id,
    required this.title,
    this.artistName,
    this.artistId,
    this.albumId,
    this.coverUrl,
    required this.audioUrl,
    this.durationSeconds = 0,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      artistName: json['artist'] ?? json['artist_name'] ?? '',
      artistId: json['artist_id']?.toString(),
      albumId: json['album_id'],
      coverUrl: json['cover_url'] ?? json['image_url'],
      audioUrl: json['audio_url'] ?? '',
      durationSeconds: json['duration_seconds'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artistName,
      'artist_id': artistId,
      'album_id': albumId,
      'cover_url': coverUrl,
      'audio_url': audioUrl,
      'duration_seconds': durationSeconds,
    };
  }
}
