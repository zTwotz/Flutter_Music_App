class Artist {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final bool isVerified;
  final int followersCount;
  final int monthlyListeners;

  Artist({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.isVerified = false,
    this.followersCount = 0,
    this.monthlyListeners = 0,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatar_url'],
      coverUrl: json['cover_url'],
      bio: json['bio'],
      isVerified: json['verified'] ?? false,
      followersCount: json['followers_count_cache'] ?? 0,
      monthlyListeners: json['monthly_listeners_current'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'bio': bio,
      'verified': isVerified,
      'followers_count_cache': followersCount,
      'monthly_listeners_current': monthlyListeners,
    };
  }
}
