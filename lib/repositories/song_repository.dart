import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song.dart';

class SongRepository {
  final SupabaseClient _supabase;

  SongRepository(this._supabase);

  /// Fetch songs for the "Trending" section, ordered by like count.
  Future<List<Song>> fetchTrendingSongs({int limit = 50}) async {
    final response = await _supabase
        .from('songs')
        .select()
        .eq('is_active', true)
        .order('like_count_cache', ascending: false)
        .limit(limit);

    return (response as List).map((e) => Song.fromJson(e)).toList();
  }

  /// Fetch all songs for a general picker, with optional search query.
  Future<List<Song>> fetchAllSongs({String? query, int limit = 100}) async {
    var q = _supabase
        .from('songs')
        .select()
        .eq('is_active', true);

    if (query != null && query.isNotEmpty) {
      q = q.or('title.ilike.%$query%,artist.ilike.%$query%');
    }

    final response = await q
        .order('like_count_cache', ascending: false)
        .limit(limit);

    return (response as List).map((e) => Song.fromJson(e)).toList();
  }

  /// Get a single song by its ID.
  Future<Song?> getSongById(int songId) async {
    final response = await _supabase
        .from('songs')
        .select()
        .eq('id', songId)
        .maybeSingle();
    
    if (response == null) return null;
    return Song.fromJson(response);
  }

  /// Fetch all songs associated with an artist.
  Future<List<Song>> fetchSongsByArtist(String artistId, {int limit = 20}) async {
    final response = await _supabase
        .from('songs')
        .select()
        .eq('artist_id', artistId)
        .eq('is_active', true)
        .limit(limit);

    return (response as List).map((e) => Song.fromJson(e)).toList();
  }
}
