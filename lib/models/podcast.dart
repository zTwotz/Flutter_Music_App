class Podcast {
  final String id;
  final String title;
  final String? description;
  final String? coverUrl;
  final String? audioUrl;
  final int durationSeconds;
  final int listenCount;
  final String? channelId;
  final String? channelName;
  final String? channelAvatarUrl;
  final DateTime? createdAt;

  Podcast({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    this.audioUrl,
    this.durationSeconds = 0,
    this.listenCount = 0,
    this.channelId,
    this.channelName,
    this.channelAvatarUrl,
    this.createdAt,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    // Support nested channel join from 'podcast_channels'
    final channel = json['podcast_channels'];
    return Podcast(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      coverUrl: json['cover_url'],
      audioUrl: json['audio_url'],
      durationSeconds: json['duration_seconds'] ?? 0,
      listenCount: json['listen_count'] ?? 0,
      channelId: json['channel_id']?.toString(),
      channelName: channel != null ? channel['name'] : json['channel_name'],
      channelAvatarUrl: channel != null ? channel['avatar_url'] : null,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_url': coverUrl,
      'audio_url': audioUrl,
      'duration_seconds': durationSeconds,
      'listen_count': listenCount,
      'channel_id': channelId,
      'channel_name': channelName,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
