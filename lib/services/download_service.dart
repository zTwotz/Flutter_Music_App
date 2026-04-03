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

  /// Helper to get safe directory. path_provider doesn't work on Web.
  Future<String?> _getSafeDownloadDir() async {
    if (identical(0, 0.0)) return null; // Simple check for web
    try {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } catch (e) {
      print('Path provider error: $e');
      return null;
    }
  }

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
      orElse: () => SongDownload(id: -1, title: '', localAudioPath: '', downloadedAt: DateTime.now())
    );
    if (download.id == -1) return false;
    
    // Check if file actually exists on disk
    return await File(download.localAudioPath).exists();
  }

  /// Downloads and registers song files.
  Future<void> downloadSong(Song song, {Function(int, int)? onProgress}) async {
    final rootPath = await _getSafeDownloadDir();
    if (rootPath == null) {
      throw Exception('Tính năng tải xuống chỉ khả dụng trên ứng dụng di động (Android/iOS). Web không hỗ trợ lưu trữ tệp tin cục bộ.');
    }

    final downloadPath = '$rootPath/downloads/${song.id}';
    final downloadDir = Directory(downloadPath);
    
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }


    String? audioPath;
    String? localCoverPath;
    String? localLyricsPath;

    try {
      // 1. Download Audio (MANDATORY)
      audioPath = '$downloadPath/${song.id}.mp3';
      try {
        await _dio.download(
          song.audioUrl, 
          audioPath, 
          onReceiveProgress: onProgress,
        );
      } catch (e) {
        if (await File(audioPath).exists()) await File(audioPath).delete();
        throw Exception('Lỗi tải file âm thanh (bắt buộc): $e');
      }

      // 2. Download Image (OPTIONAL)
      if (song.coverUrl != null && song.coverUrl!.isNotEmpty) {
        try {
          final ext = song.coverUrl!.split('.').last.split('?').first;
          localCoverPath = '$downloadPath/cover.$ext';
          await _dio.download(song.coverUrl!, localCoverPath);
        } catch (e) {
          print('Lưu ý: Tải ảnh bìa thất bại, vẫn tiếp tục: $e');
          localCoverPath = null;
        }
      }

      // 3. Download Lyrics (OPTIONAL)
      if (song.lyricsUrl != null && song.lyricsUrl!.isNotEmpty) {
        try {
          localLyricsPath = '$downloadPath/lyrics.lrc';
          await _dio.download(song.lyricsUrl!, localLyricsPath);
        } catch (e) {
          print('Lưu ý: Tải lời bài hát thất bại, vẫn tiếp tục: $e');
          localLyricsPath = null;
        }
      }

      // 4. Register to metadata storage
      final downloads = await getAllDownloads();
      final newDownload = SongDownload(
        id: song.id,
        title: song.title,
        artistName: song.artistName,
        coverUrl: song.coverUrl,
        audioUrl: song.audioUrl,
        lyricsUrl: song.lyricsUrl,
        durationSeconds: song.durationSeconds,
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
      if (await downloadDir.exists() && audioPath != null) {
         // If audio was the reason for failure, cleanup
         if (await File(audioPath).exists()) await File(audioPath).delete();
      }
      rethrow;
    }
  }


  /// Deletes local files and unregisters the song.
  Future<void> removeDownloadedSong(int songId) async {
    try {
      final rootPath = await _getSafeDownloadDir();
      if (rootPath != null) {
        final downloadDir = Directory('$rootPath/downloads/$songId');
        if (await downloadDir.exists()) {
          await downloadDir.delete(recursive: true);
        }
      }


      final downloads = await getAllDownloads();
      downloads.removeWhere((d) => d.id == songId);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, SongDownload.encode(downloads));
    } catch (e) {
      print('Error removing download: $e');
    }
  }

  /// Scans all downloads and removes those whose audio file no longer exists.
  Future<void> clearInvalidDownloadedSongs() async {
    final downloads = await getAllDownloads();
    final List<SongDownload> validDownloads = [];
    bool changed = false;

    for (final d in downloads) {
      if (await File(d.localAudioPath).exists()) {
        validDownloads.add(d);
      } else {
        changed = true;
        // Also try to cleanup directory if it partially exists
        try {
          final fileDir = File(d.localAudioPath).parent;
          if (await fileDir.exists()) {
            await fileDir.delete(recursive: true);
          }
        } catch (_) {}
      }
    }

    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, SongDownload.encode(validDownloads));
    }
  }
}

