import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import '../models/podcast.dart';

class SearchRepository {
  final SupabaseClient _supabase;

  SearchRepository(this._supabase);

  // ─── Multi-Entity Search ──────────────────────────────────────────────────
  
  Future<List<Song>> searchSongs(String query) async {
    final response = await _supabase
        .from('songs')
        .select()
        .ilike('title', '%$query%')
        .eq('is_active', true)
        .limit(10);
    return (response as List).map((e) => Song.fromJson(e)).toList();
  }

  Future<List<Artist>> searchArtists(String query) async {
    final response = await _supabase
        .from('artists')
        .select()
        .ilike('name', '%$query%')
        .eq('verified', true)
        .limit(10);
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

  // ─── Search History ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRecentSearches(String userId) async {
    final response = await _supabase
        .from('user_recent_searches')
        .select()
        .eq('user_id', userId)
        .order('searched_at', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> saveSearch(String userId, String keyword) async {
    // Upsert or handle duplicates in your DB logic
    // For now, a simple insert is fine
    await _supabase.from('user_recent_searches').upsert({
      'user_id': userId,
      'keyword': keyword,
      'searched_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id, keyword'); 
    // Assuming there's a unique constraint on (user_id, keyword) or ID handles it.
  }

  Future<void> clearRecentSearches(String userId) async {
    await _supabase.from('user_recent_searches').delete().eq('user_id', userId);
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
}
