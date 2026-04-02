import 'package:dio/dio.dart';
import '../models/song.dart';
import '../models/lyrics_data.dart';
import '../helpers/lyrics_parser.dart';

class LyricsRepository {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 1),
    receiveTimeout: const Duration(seconds: 1),
  ));

  // A simple in-memory cache
  final Map<int, LyricsData> _cache = {};

  Future<LyricsData> getLyricsForSong(Song song) async {
    // 1. Check cache
    if (_cache.containsKey(song.id)) {
      return _cache[song.id]!;
    }

    // 2. Immediate check for missing or invalid metadata
    final hasNoUrl = song.lyricsUrl == null || song.lyricsUrl!.isEmpty;
    final isInvalidUrl = !hasNoUrl && !song.lyricsUrl!.toLowerCase().endsWith('.lrc');
    
    if (hasNoUrl && (song.lyrics == null || song.lyrics!.isEmpty)) {
      return LyricsData.empty();
    }
    
    if (isInvalidUrl && (song.lyrics == null || song.lyrics!.isEmpty)) {
      return LyricsData.empty();
    }

    // 3. Priority: Fetch from URL if available
    if (!hasNoUrl && !isInvalidUrl) {
      try {
        final response = await _dio.get(song.lyricsUrl!);
        final rawContent = response.data.toString();
        final lyricsData = _processRawContent(rawContent);
        _cache[song.id] = lyricsData;
        return lyricsData;
      } catch (e) {
        // Fallback to embedded lyrics if fetch fails
        if (song.lyrics != null && song.lyrics!.isNotEmpty) {
          return _processRawContent(song.lyrics!);
        }
        rethrow;
      }
    }

    // 3. Fallback: Use embedded lyrics from the model
    if (song.lyrics != null && song.lyrics!.isNotEmpty) {
      final lyricsData = _processRawContent(song.lyrics!);
      _cache[song.id] = lyricsData;
      return lyricsData;
    }

    return LyricsData.empty();
  }

  LyricsData _processRawContent(String raw) {
    final lines = LyricsParser.parse(raw);
    final isSynced = raw.contains(RegExp(r'\[\d{2}:\d{2}\.\d{2,3}\]'));
    
    return LyricsData(
      rawText: raw,
      isSynced: isSynced,
      lines: lines,
    );
  }
}
