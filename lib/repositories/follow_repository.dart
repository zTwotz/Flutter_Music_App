import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/artist.dart';

class FollowRepository {
  final SupabaseClient _supabase;

  FollowRepository(this._supabase);

  /// Check if an artist is followed by a user.
  Future<bool> isArtistFollowed(String userId, String artistId) async {
    final response = await _supabase
        .from('user_followed_artists')
        .select('id')
        .eq('user_id', userId)
        .eq('artist_id', artistId)
        .maybeSingle();
        
    return response != null;
  }

  /// Toggle following status for an artist.
  /// Calls Supabase RPCs to update follower counts in the background.
  Future<void> toggleFollow(String userId, String artistId, bool isAlreadyFollowing) async {
    if (isAlreadyFollowing) {
      await _supabase
          .from('user_followed_artists')
          .delete()
          .match({'user_id': userId, 'artist_id': artistId});
          
      // Try to decrement count cache via RPC
      await _supabase.rpc('decrement_artist_followers', params: {'artist_id_param': artistId}).catchError((_) {});
    } else {
      await _supabase.from('user_followed_artists').insert({
        'user_id': userId,
        'artist_id': artistId,
      });
      
      // Try to increment count cache via RPC
      await _supabase.rpc('increment_artist_followers', params: {'artist_id_param': artistId}).catchError((_) {});
    }
  }

  /// Fetch all artists followed by a user.
  Future<List<Artist>> fetchFollowedArtists(String userId) async {
    final response = await _supabase
        .from('user_followed_artists')
        .select('artist_id, artists(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .where((row) => row['artists'] != null)
        .map((row) => Artist.fromJson(row['artists'] as Map<String, dynamic>))
        .toList();
  }
}
