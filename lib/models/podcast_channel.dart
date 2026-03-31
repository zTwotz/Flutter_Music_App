class PodcastChannel {
  final String id;
  final String name;
  final String? avatarUrl;
  final int subscriberCount;
  final DateTime? createdAt;

  PodcastChannel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.subscriberCount = 0,
    this.createdAt,
  });

  factory PodcastChannel.fromJson(Map<String, dynamic> json) {
    return PodcastChannel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatar_url'],
      subscriberCount: json['subscriber_count'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'subscriber_count': subscriberCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
