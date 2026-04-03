import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import '../models/podcast.dart';
import '../helpers/local_recent_search_helper.dart';

class SearchRepository {
  final SupabaseClient _supabase;

  SearchRepository(this._supabase);

  // ─── Multi-Entity Search ──────────────────────────────────────────────────
  
  Future<List<Song>> searchSongs(String query) async {
    try {
      // Step 1: Search by title
      final titleResponse = await _supabase
          .from('songs')
          .select()
          .ilike('title', '%$query%')
          .eq('is_active', true)
          .limit(20);

      // Step 2: Search by genre join
      final genreResponse = await _supabase
          .from('songs')
          .select('*, song_genres!inner(genres!inner(name))')
          .ilike('song_genres.genres.name', '%$query%')
          .eq('is_active', true)
          .limit(20);

      // Step 3: Search by mood join
      final moodResponse = await _supabase
          .from('songs')
          .select('*, song_moods!inner(moods!inner(name))')
          .ilike('song_moods.moods.name', '%$query%')
          .eq('is_active', true)
          .limit(20);

      // Combine and remove duplicates based on song ID
      final Map<int, Song> uniqueSongs = {};
      
      for (var s in (titleResponse as List)) {
        final song = Song.fromJson(s);
        uniqueSongs[song.id] = song;
      }
      
      for (var s in (genreResponse as List)) {
        final song = Song.fromJson(s);
        uniqueSongs[song.id] = song;
      }

      for (var s in (moodResponse as List)) {
        final song = Song.fromJson(s);
        uniqueSongs[song.id] = song;
      }

      // Step 4: Search by hashtag join
      final hashtagResponse = await _supabase
          .from('songs')
          .select('*, song_hashtags!inner(hashtags!inner(name))')
          .ilike('song_hashtags.hashtags.name', '%$query%')
          .eq('is_active', true)
          .limit(20);

      for (var s in (hashtagResponse as List)) {
        final song = Song.fromJson(s);
        uniqueSongs[song.id] = song;
      }

      return uniqueSongs.values.toList();
    } catch (e) {
      // Fallback to simple title search if Join fails (e.g. table mapping issues)
      final fallback = await _supabase
          .from('songs')
          .select()
          .ilike('title', '%$query%')
          .eq('is_active', true)
          .limit(20);
      return (fallback as List).map((e) => Song.fromJson(e)).toList();
    }
  }

  Future<List<Artist>> searchArtists(String query) async {
    final response = await _supabase
        .from('artists')
        .select()
        .ilike('name', '%$query%')
        .limit(20);
    return (response as List).map((e) => Artist.fromJson(e)).toList();
  }

  Future<List<Album>> searchAlbums(String query) async {
    final response = await _supabase
        .from('albums')
        .select()
        .ilike('title', '%$query%')
        .limit(10);
    return (response as List).map((e) => Album.fromJson(e)).toList();
  }

  Future<List<Playlist>> searchPlaylists(String query) async {
    final response = await _supabase
        .from('playlists')
        .select()
        .ilike('name', '%$query%')
        .eq('is_public', true)
        .limit(10);
    return (response as List).map((e) => Playlist.fromJson(e)).toList();
  }

  Future<List<Podcast>> searchPodcasts(String query) async {
    final response = await _supabase
        .from('podcasts')
        .select('*, podcast_channels(id, name)')
        .ilike('title', '%$query%')
        .limit(10);
    return (response as List).map((e) => Podcast.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> searchGenres(String query) async {
    final response = await _supabase
        .from('genres')
        .select()
        .ilike('name', '%$query%')
        .eq('is_active', true)
        .limit(5);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> searchMoods(String query) async {
    try {
      final response = await _supabase
          .from('moods')
          .select()
          .ilike('name', '%$query%')
          .eq('is_active', true)
          .limit(5);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchHashtags(String query) async {
    final response = await _supabase
        .from('hashtags')
        .select()
        .ilike('name', '%$query%')
        .eq('is_active', true)
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  // ─── Search History ────────────────────────────────────────────────────────

  final LocalRecentSearchHelper _localHelper = LocalRecentSearchHelper();

  Future<List<Map<String, dynamic>>> getRecentSearches(String? userId) async {
    // Always use local helper as requested (save local for everyone)
    return await _localHelper.getRecentSearches();
  }

  Future<void> saveSearchItem({
    String? userId,
    required String keyword,
    required String contentType,
    String? contentId,
    required String title,
    String? subtitle,
    String? imageUrl,
  }) async {
    final item = {
      'keyword': keyword,
      'content_type': contentType,
      'content_id': contentId,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Always use local helper
    await _localHelper.saveSearch(item);
  }

  Future<void> clearRecentSearches(String? userId) async {
    // Always clear local
    await _localHelper.clearAll();
  }

  Future<void> removeSearchItem({
    String? userId,
    required String contentType,
    String? contentId,
    String? keyword,
  }) async {
    // Always remove from local
    await _localHelper.removeSearch({
      'content_type': contentType,
      'content_id': contentId,
      'keyword': keyword,
    });
  }

  // ─── Discovery Data ────────────────────────────────────────────────────────

  Future<List<String>> getTrendingKeywords() async {
    final response = await _supabase
        .from('trending_search_keywords')
        .select('keyword')
        .limit(5);
    return (response as List).map((e) => e['keyword'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getHashtags() async {
    final response = await _supabase
        .from('hashtags')
        .select()
        .eq('is_active', true)
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getGenres() async {
    final response = await _supabase
        .from('genres')
        .select()
        .eq('is_active', true)
        .limit(20);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMoods() async {
    try {
      final response = await _supabase
          .from('moods')
          .select()
          .eq('is_active', true)
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // If moods table doesn't exist yet, gracefully return empty
      return [];
    }
  }
}
