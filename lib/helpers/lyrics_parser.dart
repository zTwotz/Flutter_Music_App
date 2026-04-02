import '../models/lyric_line.dart';

class LyricsParser {
  /// Parses raw LRC or TXT content into a list of LyricLine.
  /// Supports:
  /// - Standard formats: [mm:ss.xx] or [mm:ss.xxx]
  /// - Simplified formats: [mm:ss]
  /// - Multiple timestamps per line: [mm:ss.xx][mm:ss.yy] Lyrics
  /// - Filters out metadata tags: [ti: title], [ar: artist], etc.
  static List<LyricLine> parse(String content) {
    if (content.isEmpty) return [];

    final List<LyricLine> allLines = [];
    
    // Split into individual lines
    final rawLines = content.split('\n');
    
    // Regex to find all timestamps in a single string
    // Matches patterns like [00:12.34] or [00:12]
    final timestampRegex = RegExp(r'\[(\d{2}):(\d{2})(?:\.(\d{2,3}))?\]');
    
    // Regex for metadata tags like [ti: song title]
    final metadataRegex = RegExp(r'\[[a-z]{2,}:.*\]', caseSensitive: false);

    for (var line in rawLines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Skip metadata tags completely
      if (metadataRegex.hasMatch(line) && !timestampRegex.hasMatch(line)) {
        continue;
      }

      // Find all timestamps in the line
      final matches = timestampRegex.allMatches(line).toList();
      
      if (matches.isEmpty) {
        // Plain text line (no timestamp)
        allLines.add(LyricLine(time: Duration.zero, text: line));
        continue;
      }

      // Extract the text part (everything after the last timestamp)
      final lastMatch = matches.last;
      final textContent = line.substring(lastMatch.end).trim();
      
      if (textContent.isEmpty) continue;

      // Create a LyricLine for each timestamp found in this line
      for (final match in matches) {
        try {
          final int min = int.parse(match.group(1)!);
          final int sec = int.parse(match.group(2)!);
          final String? msStr = match.group(3);
          
          int ms = 0;
          if (msStr != null) {
            ms = int.parse(msStr);
            // Handle 2 digits as centiseconds (10ms each)
            if (msStr.length == 2) ms *= 10;
          }

          final duration = Duration(minutes: min, seconds: sec, milliseconds: ms);
          allLines.add(LyricLine(time: duration, text: textContent));
        } catch (_) {
          // Skip invalid timestamp formats silently
        }
      }
    }

    // Sort all lines by timestamp to ensure chronological order
    allLines.sort((a, b) => a.time.compareTo(b.time));
    
    return allLines;
  }
}
