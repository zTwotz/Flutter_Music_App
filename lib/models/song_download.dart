import 'dart:convert';

class SongDownload {
  final int id;
  final String title;
  final String? artistName;
  final String? coverUrl;
  final String? audioUrl;
  final String? lyricsUrl;
  final String localAudioPath;
  final String? localCoverPath;
  final String? localLyricsPath;
  final int? durationSeconds;
  final DateTime downloadedAt;

  SongDownload({
    required this.id,
    required this.title,
    this.artistName,
    this.coverUrl,
    this.audioUrl,
    this.lyricsUrl,
    required this.localAudioPath,
    this.localCoverPath,
    this.localLyricsPath,
    this.durationSeconds,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artistName': artistName,
    'coverUrl': coverUrl,
    'audioUrl': audioUrl,
    'lyricsUrl': lyricsUrl,
    'localAudioPath': localAudioPath,
    'localCoverPath': localCoverPath,
    'localLyricsPath': localLyricsPath,
    'durationSeconds': durationSeconds,
    'downloadedAt': downloadedAt.toIso8601String(),
  };

  factory SongDownload.fromJson(Map<String, dynamic> json) => SongDownload(
    id: json['id'],
    title: json['title'] ?? 'Unknown',
    artistName: json['artistName'],
    coverUrl: json['coverUrl'],
    audioUrl: json['audioUrl'],
    lyricsUrl: json['lyricsUrl'],
    localAudioPath: json['localAudioPath'],
    localCoverPath: json['localCoverPath'],
    localLyricsPath: json['localLyricsPath'],
    durationSeconds: json['durationSeconds'],
    downloadedAt: DateTime.parse(json['downloadedAt']),
  );

  static String encode(List<SongDownload> downloads) => json.encode(
    downloads.map<Map<String, dynamic>>((d) => d.toJson()).toList(),
  );

  static List<SongDownload> decode(String downloads) =>
    (json.decode(downloads) as List<dynamic>)
      .map<SongDownload>((item) => SongDownload.fromJson(item))
      .toList();
}

