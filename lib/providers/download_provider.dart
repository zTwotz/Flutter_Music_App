import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/download_service.dart';
import '../models/song_download.dart';

class DownloadNotifier extends Notifier<List<SongDownload>> {
  @override
  List<SongDownload> build() {
    _loadDownloads();
    return [];
  }

  Future<void> _loadDownloads() async {
    final downloads = await DownloadService().getAllDownloads();
    state = downloads;
  }

  /// Initiates song download and updates the state.
  Future<void> startDownload(dynamic song) async {
    try {
      await DownloadService().downloadSong(song);
      await _loadDownloads();
    } catch (_) {
      rethrow;
    }
  }

  /// Removes a song and updates the state.
  Future<void> removeDownload(int songId) async {
    await DownloadService().removeDownloadedSong(songId);
    await _loadDownloads();
  }

  /// Quick check for UI state
  bool isDownloaded(int songId) {
    return state.any((d) => d.id == songId);
  }
}

final downloadProvider = NotifierProvider<DownloadNotifier, List<SongDownload>>(DownloadNotifier.new);
