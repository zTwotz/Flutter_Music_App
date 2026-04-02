import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/lyrics_data.dart';
import '../repositories/lyrics_repository.dart';
import '../providers/player_provider.dart';

final lyricsRepositoryProvider = Provider((ref) => LyricsRepository());

// Fetching lyrics data
final lyricsDataProvider = FutureProvider.family<LyricsData, Song>((ref, song) async {
  final repo = ref.watch(lyricsRepositoryProvider);
  return await repo.getLyricsForSong(song);
});

// Calculate active line index based on position
final currentLyricIndexProvider = Provider.family<int, Song>((ref, song) {
  final lyricsDataAsync = ref.watch(lyricsDataProvider(song));
  
  return lyricsDataAsync.maybeWhen(
    data: (data) {
      if (!data.isSynced || data.isEmpty) return -1;

      final positionData = ref.watch(positionDataProvider).value;
      final position = positionData?.position ?? Duration.zero;

      // Binary search for the active line for better performance with large LRCs
      final lines = data.lines;
      int low = 0;
      int high = lines.length - 1;
      int result = -1;

      while (low <= high) {
        int mid = (low + high) ~/ 2;
        if (lines[mid].time <= position) {
          result = mid;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }
      return result;
    },
    orElse: () => -1,
  );
});
