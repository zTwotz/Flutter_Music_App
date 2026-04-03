import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/download_service.dart';
import '../models/song_download.dart';
import '../models/song.dart';
import '../repositories/offline_repository.dart';

class DownloadState {
  final List<SongDownload> downloads;
  final Map<int, double> progress; // songId -> 0.0 to 1.0
  final bool isLoading;

  DownloadState({
    this.downloads = const [],
    this.progress = const {},
    this.isLoading = false,
  });

  DownloadState copyWith({
    List<SongDownload>? downloads,
    Map<int, double>? progress,
    bool? isLoading,
  }) {
    return DownloadState(
      downloads: downloads ?? this.downloads,
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DownloadNotifier extends Notifier<DownloadState> {
  final _service = DownloadService();
  
  @override
  DownloadState build() {
    _loadInitial();
    return DownloadState();
  }

  Future<void> _loadInitial() async {
    final list = await _service.getAllDownloads();
    state = state.copyWith(downloads: list);
  }

  Future<void> refresh() async => _loadInitial();

  Future<void> startDownload(Song song) async {
    // Prevent double download
    if (state.progress.containsKey(song.id)) return;

    // Set initial progress
    state = state.copyWith(
      progress: {...state.progress, song.id: 0.0}
    );

    try {
      await _service.downloadSong(
        song,
        onProgress: (received, total) {
          if (total != -1) {
            final p = received / total;
            state = state.copyWith(
              progress: {...state.progress, song.id: p}
            );
          }
        },
      );
      
      // Complete
      await _loadInitial();
      state = state.copyWith(
        progress: Map.from(state.progress)..remove(song.id)
      );
    } catch (e) {
      state = state.copyWith(
        progress: Map.from(state.progress)..remove(song.id)
      );
      rethrow;
    }
  }

  Future<void> removeDownload(int songId) async {
    state = state.copyWith(isLoading: true);
    await _service.removeDownloadedSong(songId);
    await _loadInitial();
    state = state.copyWith(isLoading: false);
  }

  bool isDownloaded(int songId) {
    return state.downloads.any((d) => d.id == songId);
  }
  
  double? getProgress(int songId) => state.progress[songId];

  Future<void> clearInvalidDownloads() async {
    await _service.clearInvalidDownloadedSongs();
    await _loadInitial();
  }
}



final downloadProvider = NotifierProvider<DownloadNotifier, DownloadState>(() => DownloadNotifier());

final offlineRepositoryProvider = Provider((ref) => OfflineRepository());

final downloadedSongsProvider = FutureProvider<List<Song>>((ref) async {
  // Reaction to changes in downloads list
  ref.watch(downloadProvider); 
  return ref.read(offlineRepositoryProvider).fetchDownloadedSongs();
});


