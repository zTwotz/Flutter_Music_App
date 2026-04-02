import 'lyric_line.dart';

class LyricsData {
  final String rawText;
  final bool isSynced;
  final List<LyricLine> lines;

  LyricsData({
    required this.rawText,
    required this.isSynced,
    required this.lines,
  });

  bool get isEmpty => lines.isEmpty;

  factory LyricsData.empty() => LyricsData(rawText: '', isSynced: false, lines: []);
}
