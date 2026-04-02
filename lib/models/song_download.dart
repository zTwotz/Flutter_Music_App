import 'dart:convert';

class SongDownload {
  final int id;
  final String localAudioPath;
  final String? localCoverPath;
  final String? localLyricsPath;
  final DateTime downloadedAt;

  SongDownload({
    required this.id,
    required this.localAudioPath,
    this.localCoverPath,
    this.localLyricsPath,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'localAudioPath': localAudioPath,
    'localCoverPath': localCoverPath,
    'localLyricsPath': localLyricsPath,
    'downloadedAt': downloadedAt.toIso8601String(),
  };

  factory SongDownload.fromJson(Map<String, dynamic> json) => SongDownload(
    id: json['id'],
    localAudioPath: json['localAudioPath'],
    localCoverPath: json['localCoverPath'],
    localLyricsPath: json['localLyricsPath'],
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
