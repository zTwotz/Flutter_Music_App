import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song.dart';

class FavoriteRepository {
  final SupabaseClient _supabase;

  FavoriteRepository(this._supabase);

  /// Check if a song is liked by a specific user.
  Future<bool> isSongLiked(String userId, int songId) async {
    final response = await _supabase
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('song_id', songId)
        .maybeSingle();
    return response != null;
  }

  /// Toggle like status for a song.
  /// Calls Supabase RPCs to update like counts in the background.
  Future<void> toggleLike(String userId, int songId, bool isAlreadyLiked) async {
    if (isAlreadyLiked) {
      await _supabase.from('favorites').delete().match({
        'user_id': userId,
        'song_id': songId,
      });
      // Try to decrement count cache via RPC
      await _supabase.rpc('decrement_song_likes', params: {'song_id_param': songId}).catchError((_) {});
    } else {
      await _supabase.from('favorites').insert({
        'user_id': userId,
        'song_id': songId,
      });
      // Try to increment count cache via RPC
      await _supabase.rpc('increment_song_likes', params: {'song_id_param': songId}).catchError((_) {});
    }
  }

  /// Fetch all songs liked by a user.
  Future<List<Song>> fetchLikedSongs(String userId) async {
    final response = await _supabase
        .from('favorites')
        .select('song_id, songs(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .where((row) => row['songs'] != null)
        .map((row) => Song.fromJson(row['songs'] as Map<String, dynamic>))
        .toList();
  }

  /// Get the total count of liked songs for a user.
  Future<int> getLikedSongsCount(String userId) async {
    final response = await _supabase
        .from('favorites')
        .select('id')
        .eq('user_id', userId);
    return (response as List).length;
  }
}
