import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/playlist.dart';
import '../models/song.dart';

class PlaylistRepository {
  final SupabaseClient _supabase;

  PlaylistRepository(this._supabase);

  /// Fetch all playlists owned by a user.
  Future<List<Playlist>> fetchUserOwnedPlaylists(String userId) async {
    final response = await _supabase
        .from('playlists')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
        
    return (response as List).map((e) => Playlist.fromJson(e)).toList();
  }

  /// Create a new playlist.
  Future<Playlist> createPlaylist({
    required String userId,
    required String name,
    String? description,
    List<int> songIds = const [],
  }) async {
    // 1. Insert the playlist
    final response = await _supabase.from('playlists').insert({
      'user_id': userId,
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      'playlist_type': 'user',
      'is_public': false,
    }).select().single();

    final playlist = Playlist.fromJson(response);

    // 2. Insert playlist_songs if any
    if (songIds.isNotEmpty) {
      await addSongsToPlaylist(playlist.id, songIds);
    }

    return playlist;
  }

  /// Add songs to a playlist with sequential positions.
  Future<void> addSongsToPlaylist(int playlistId, List<int> songIds) async {
    if (songIds.isEmpty) return;

    // Get current max position
    final existing = await _supabase
        .from('playlist_songs')
        .select('position')
        .eq('playlist_id', playlistId)
        .order('position', ascending: false)
        .limit(1);

    int nextPosition = 1;
    if ((existing as List).isNotEmpty) {
      nextPosition = (existing.first['position'] as int) + 1;
    }

    final rows = songIds.asMap().entries.map((entry) => {
      'playlist_id': playlistId,
      'song_id': entry.value,
      'position': nextPosition + entry.key,
    }).toList();

    await _supabase.from('playlist_songs').upsert(
      rows,
      onConflict: 'playlist_id,song_id',
    );
  }

  /// Remove a song from a playlist.
  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    await _supabase
        .from('playlist_songs')
        .delete()
        .match({'playlist_id': playlistId, 'song_id': songId});
  }

  /// Delete a playlist.
  Future<void> deletePlaylist(int playlistId) async {
    await _supabase.from('playlists').delete().eq('id', playlistId);
  }

  /// Rename a playlist.
  Future<void> renamePlaylist(int playlistId, String newName) async {
    await _supabase
        .from('playlists')
        .update({'name': newName})
        .eq('id', playlistId);
  }
}
