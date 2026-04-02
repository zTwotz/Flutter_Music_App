import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/song_download.dart';

class DownloadService {
  static const String _storageKey = 'song_downloads';
  final Dio _dio = Dio();

  // Singleton
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  /// Gets all records of downloaded songs from storage.
  Future<List<SongDownload>> getAllDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_storageKey);
    if (encoded == null) return [];
    try {
      return SongDownload.decode(encoded);
    } catch (_) {
      return [];
    }
  }

  /// Checks if a song is fully downloaded and registered.
  Future<bool> isSongDownloaded(int songId) async {
    final downloads = await getAllDownloads();
    final download = downloads.firstWhere(
      (d) => d.id == songId,
      orElse: () => SongDownload(id: -1, localAudioPath: '', downloadedAt: DateTime.now())
    );
    if (download.id == -1) return false;
    
    // Check if file actually exists on disk
    return await File(download.localAudioPath).exists();
  }

  /// Downloads and registers song files.
  Future<void> downloadSong(Song song, {Function(int, int)? onProgress}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${dir.path}/downloads/${song.id}');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // 1. Download Audio
      final audioPath = '${downloadDir.path}/${song.id}.mp3';
      await _dio.download(song.audioUrl, audioPath, onReceiveProgress: onProgress);

      // 2. Download Image
      String? localCoverPath;
      if (song.coverUrl != null) {
        final ext = song.coverUrl!.split('.').last.split('?').first;
        localCoverPath = '${downloadDir.path}/cover.$ext';
        await _dio.download(song.coverUrl!, localCoverPath);
      }

      // 3. Download Lyrics
      String? localLyricsPath;
      if (song.lyricsUrl != null) {
        localLyricsPath = '${downloadDir.path}/lyrics.lrc';
        await _dio.download(song.lyricsUrl!, localLyricsPath);
      }

      // 4. Register to metadata storage
      final downloads = await getAllDownloads();
      final newDownload = SongDownload(
        id: song.id,
        localAudioPath: audioPath,
        localCoverPath: localCoverPath,
        localLyricsPath: localLyricsPath,
        downloadedAt: DateTime.now(),
      );
      
      downloads.removeWhere((d) => d.id == song.id);
      downloads.add(newDownload);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, SongDownload.encode(downloads));

    } catch (e) {
      throw Exception('Lỗi quá trình tải xuống: $e');
    }
  }

  /// Deletes local files and unregisters the song.
  Future<void> removeDownloadedSong(int songId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${dir.path}/downloads/$songId');
      if (await downloadDir.exists()) {
        await downloadDir.delete(recursive: true);
      }

      final downloads = await getAllDownloads();
      downloads.removeWhere((d) => d.id == songId);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, SongDownload.encode(downloads));
    } catch (e) {
      print('Erro removing download: $e');
    }
  }
}
