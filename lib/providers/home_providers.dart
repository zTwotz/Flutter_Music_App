import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_provider.dart';
import 'auth_provider.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../models/artist.dart';
import '../models/album.dart';

// ─── Filter Chip Enum ──────────────────────────────────────────────────────────
enum HomeFilter { all, music, musicFollowing, podcasts, podcastsFollowing }

class HomeFilterNotifier extends Notifier<HomeFilter> {
  @override
  HomeFilter build() => HomeFilter.all;

  void setFilter(HomeFilter filter) => state = filter;
}

final homeFilterProvider = NotifierProvider<HomeFilterNotifier, HomeFilter>(
  HomeFilterNotifier.new,
);

// ─── Songs Provider ────────────────────────────────────────────────────────────
final trendingSongsProvider = FutureProvider<List<Song>>((ref) async {
  final songs = await ref.watch(songRepositoryProvider).fetchTrendingSongs();
  return songs.toList()..shuffle();
});

// ─── System Playlists ─────────────────────────────────────────────────────────
final systemPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final playlists = await ref.watch(collectionRepositoryProvider).fetchSystemPlaylists();
  return playlists.toList()..shuffle();
});

// ─── All Artists ──────────────────────────────────────────────────────────────
final artistsProvider = FutureProvider<List<Artist>>((ref) async {
  final artists = await ref.watch(artistRepositoryProvider).fetchPopularArtists();
  return artists.toList()..shuffle();
});

// ─── Top 10 Artists ──────────────────────────────────────────────────────────
final top10ArtistsProvider = FutureProvider<List<Artist>>((ref) async {
  final artists = await ref.watch(artistRepositoryProvider).fetchPopularArtists(limit: 50); // Fetch more then shuffle and take top
  return (artists.toList()..shuffle()).take(10).toList();
});

// ─── New Albums ──────────────────────────────────────────────────────────────
final newAlbumsProvider = FutureProvider<List<Album>>((ref) async {
  final albums = await ref.watch(collectionRepositoryProvider).fetchNewAlbums();
  return albums.toList()..shuffle();
});

// ─── Recent Plays ────────────────────────────────────────────────────────────
final recentPlaysProvider = FutureProvider<List<dynamic>>((ref) async {
  final user = ref.watch(authStateProvider).value?.session?.user;
  if (user == null) return [];
  return ref.watch(playerRepositoryProvider).fetchRecentPlays(user.id);
});

// ─── All Podcasts ─────────────────────────────────────────────────────────────
// Moved to podcast_providers.dart


// ─── Auth-gated: Followed Artists ────────────────────────────────────────────
final followedArtistsProvider = FutureProvider<List<Artist>>((ref) async {
  final user = ref.watch(authStateProvider).value?.session?.user;
  if (user == null) return [];
  return ref.watch(followRepositoryProvider).fetchFollowedArtists(user.id);
});

// ─── Auth-gated: Subscribed Podcast Channels ─────────────────────────────────
// Moved to podcast_providers.dart


// ─── Songs expand/collapse ────────────────────────────────────────────────────
class _BoolNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
  // ignore: use_setters_to_change_properties
  void setValue(bool v) => state = v;
}

final songsExpandedProvider = NotifierProvider<_BoolNotifier, bool>(_BoolNotifier.new);
final podcastsExpandedProvider = NotifierProvider<_BoolNotifier, bool>(_BoolNotifier.new);
