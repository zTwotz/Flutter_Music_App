import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';

final lyricsProvider = FutureProvider.family<String?, Song>((ref, song) async {
  // If we already have lyrics text in the model
  if (song.lyrics != null && song.lyrics!.isNotEmpty) {
    return song.lyrics;
  }

  // If we have a URL to fetch from
  if (song.lyricsUrl != null && song.lyricsUrl!.isNotEmpty) {
    try {
      final response = await Dio().get(song.lyricsUrl!);
      return response.data.toString();
    } catch (e) {
      throw Exception('Không thể tải lời bài hát');
    }
  }

  return null;
});
