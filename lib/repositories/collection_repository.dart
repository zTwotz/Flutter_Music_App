import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/playlist.dart';
import '../models/album.dart';
import '../models/song.dart';

class CollectionRepository {
  final SupabaseClient _supabase;

  CollectionRepository(this._supabase);

  /// Fetch system curated playlists.
  Future<List<Playlist>> fetchSystemPlaylists() async {
    final response = await _supabase
        .from('playlists')
        .select()
        .eq('playlist_type', 'system')
        .eq('is_public', true)
        .limit(10);
        
    return (response as List).map((e) => Playlist.fromJson(e)).toList();
  }

  /// Get details and songs of a playlist.
  Future<List<Song>> fetchPlaylistSongs(int playlistId) async {
    final response = await _supabase
        .from('playlist_songs')
        .select('position, songs(*)')
        .eq('playlist_id', playlistId)
        .order('position');

    return (response as List)
        .where((row) => row['songs'] != null)
        .map((row) => Song.fromJson(row['songs'] as Map<String, dynamic>))
        .toList();
  }

  /// Get details and songs of an album.
  Future<List<Song>> fetchAlbumSongs(int albumId) async {
    final response = await _supabase
        .from('album_songs')
        .select('track_number, songs(*)')
        .eq('album_id', albumId)
        .order('track_number');

    return (response as List)
        .where((row) => row['songs'] != null)
        .map((row) => Song.fromJson(row['songs'] as Map<String, dynamic>))
        .toList();
  }

  /// Check if a playlist is saved/bookmarked by a user.
  Future<bool> isPlaylistSaved(String userId, int playlistId) async {
    final response = await _supabase
        .from('user_saved_playlists')
        .select('id')
        .eq('user_id', userId)
        .eq('playlist_id', playlistId)
        .maybeSingle();
    return response != null;
  }

  /// Toggle saving/bookmarking status for a playlist.
  Future<void> toggleSavePlaylist(String userId, int playlistId, bool isAlreadySaved) async {
    if (isAlreadySaved) {
      await _supabase.from('user_saved_playlists').delete().match({
        'user_id': userId,
        'playlist_id': playlistId,
      });
    } else {
      await _supabase.from('user_saved_playlists').insert({
        'user_id': userId,
        'playlist_id': playlistId,
      });
    }
  }

  /// Fetch all playlists saved (bookmarked) by a user.
  Future<List<Playlist>> fetchSavedPlaylists(String userId) async {
    final response = await _supabase
        .from('user_saved_playlists')
        .select('playlist_id, playlists(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .where((row) => row['playlists'] != null)
        .map((row) => Playlist.fromJson(row['playlists'] as Map<String, dynamic>))
        .toList();
  }
}
