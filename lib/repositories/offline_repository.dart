import '../models/song_download.dart';
import '../services/download_service.dart';
import '../models/song.dart';

class OfflineRepository {
  final DownloadService _downloadService = DownloadService();

  /// Get all downloaded songs as a list of regular Song objects for easier UI integration
  Future<List<Song>> fetchDownloadedSongs() async {
    final downloads = await _downloadService.getAllDownloads();
    
    // Sort by downloaded date (newest first)
    downloads.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));


    return downloads.map((d) => Song(
      id: d.id,
      title: d.title,
      artistName: d.artistName,
      coverUrl: d.localCoverPath ?? d.coverUrl, // Prefer local cover
      audioUrl: d.localAudioPath, // Crucial: use local path
      durationSeconds: d.durationSeconds ?? 0,
      lyricsUrl: d.localLyricsPath,
    )).toList();
  }

  Future<void> removeDownload(int songId) async {
    await _downloadService.removeDownloadedSong(songId);
  }

  Future<bool> isDownloaded(int songId) async {
    return await _downloadService.isSongDownloaded(songId);
  }
}
