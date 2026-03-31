class Album {
  final int id;
  final String title;
  final String? coverUrl;
  final DateTime? releaseDate;
  final String type;

  Album({
    required this.id,
    required this.title,
    this.coverUrl,
    this.releaseDate,
    this.type = 'album',
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      coverUrl: json['cover_url'],
      releaseDate: json['release_date'] != null ? DateTime.tryParse(json['release_date']) : null,
      type: json['album_type'] ?? 'album',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover_url': coverUrl,
      'release_date': releaseDate?.toIso8601String(),
      'album_type': type,
    };
  }
}
