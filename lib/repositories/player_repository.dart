import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerRepository {
  final SupabaseClient _supabase;

  PlayerRepository(this._supabase);

  Future<Map<String, dynamic>?> fetchPlayerState(String userId) async {
    final response = await _supabase
        .from('player_states')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> updatePlayerState({
    required String userId,
    required String? currentSongId,
    required String? currentPlaylistId,
    required int positionSeconds,
    required String repeatMode,
    required bool shuffleEnabled,
  }) async {
    await _supabase.from('player_states').upsert({
      'user_id': userId,
      'current_song_id': currentSongId,
      'current_playlist_id': currentPlaylistId,
      'position_seconds': positionSeconds,
      'repeat_mode': repeatMode,
      'shuffle_enabled': shuffleEnabled,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> logListen({
    required String userId,
    String? songId,
    String? podcastId,
  }) async {
    await _supabase.from('listens').insert({
      'user_id': userId,
      'song_id': songId,
      'podcast_id': podcastId,
      'listened_at': DateTime.now().toIso8601String(),
    });
  }
}
