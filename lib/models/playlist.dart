class Playlist {
  final int id;
  final String name;
  final String? description;
  final String? coverUrl;
  final String type;
  final bool isSystem;
  final String? userId;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.type = 'user',
    this.isSystem = false,
    this.userId,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final playlistType = json['playlist_type'] ?? 'user';
    return Playlist(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      description: json['description'],
      coverUrl: json['cover_url'] ?? json['image_url'],
      type: playlistType,
      isSystem: playlistType == 'system',
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cover_url': coverUrl,
      'playlist_type': type,
      'user_id': userId,
    };
  }
}
