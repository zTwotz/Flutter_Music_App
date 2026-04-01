import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../providers/supabase_provider.dart';

final artistRepositoryProvider = Provider<ArtistRepository>((ref) {
  return ArtistRepository(ref.watch(supabaseClientProvider));
});

class ArtistRepository {
  final SupabaseClient _supabase;

  ArtistRepository(this._supabase);

  /// Fetch public popular artists.
  Future<List<Artist>> fetchPopularArtists({int limit = 20}) async {
    final response = await _supabase
        .from('artists')
        .select()
        .limit(limit);

    return (response as List).map((e) => Artist.fromJson(e)).toList();
  }

  /// Get detailed metadata for a single artist.
  Future<Artist> getArtistDetail(String artistId) async {
    final response = await _supabase
        .from('artists')
        .select()
        .eq('id', artistId)
        .single();
    
    return Artist.fromJson(response);
  }

  /// Fetch all songs where this artist is a primary or featured artist.
  Future<List<Song>> getArtistSongs(String artistId) async {
    // This query assumes a junction table song_artists for multi-artist support
    final response = await _supabase
        .from('song_artists')
        .select('songs(*)')
        .eq('artist_id', artistId)
        .order('artist_order');

    return (response as List)
        .where((row) => row['songs'] != null)
        .map((row) => Song.fromJson(row['songs'] as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all albums associated with this artist.
  Future<List<Album>> getArtistAlbums(String artistId) async {
    final response = await _supabase
        .from('album_artists')
        .select('albums(*)')
        .eq('artist_id', artistId)
        .order('artist_order');

    return (response as List)
        .where((row) => row['albums'] != null)
        .map((row) => Album.fromJson(row['albums'] as Map<String, dynamic>))
        .toList();
  }
}
