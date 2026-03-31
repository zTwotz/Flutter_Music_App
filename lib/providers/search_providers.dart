import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import '../models/podcast.dart';
import 'supabase_provider.dart';
import 'auth_provider.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class SearchResults {
  final List<Song> songs;
  final List<Artist> artists;
  final List<Album> albums;
  final List<Playlist> playlists;
  final List<Podcast> podcasts;

  SearchResults({
    required this.songs,
    required this.artists,
    required this.albums,
    required this.playlists,
    required this.podcasts,
  });

  factory SearchResults.empty() => SearchResults(
        songs: [],
        artists: [],
        albums: [],
        playlists: [],
        podcasts: [],
      );

  bool get isEmpty =>
      songs.isEmpty &&
      artists.isEmpty &&
      albums.isEmpty &&
      playlists.isEmpty &&
      podcasts.isEmpty;
}

// ─── Providers ───────────────────────────────────────────────────────────────

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  
  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final searchResultsProvider = FutureProvider<SearchResults>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return SearchResults.empty();

  // Debouncing: wait for 500ms
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Check if we are still the relevant future (Riverpod handles this mostly, but safety first)
  // If query changed during delay, this future might still finish, but Riverpod will use the latest one.

  final repo = ref.watch(searchRepositoryProvider);
  
  try {
    final results = await Future.wait([
      repo.searchSongs(query),
      repo.searchArtists(query),
      repo.searchAlbums(query),
      repo.searchPlaylists(query),
      repo.searchPodcasts(query),
    ]);

    return SearchResults(
      songs: results[0] as List<Song>,
      artists: results[1] as List<Artist>,
      albums: results[2] as List<Album>,
      playlists: results[3] as List<Playlist>,
      podcasts: results[4] as List<Podcast>,
    );
  } catch (e) {
    rethrow;
  }
});

final recentSearchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value?.session?.user;
  if (user == null) return [];
  
  return ref.watch(searchRepositoryProvider).getRecentSearches(user.id);
});

final trendingKeywordsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(searchRepositoryProvider).getTrendingKeywords();
});

final hashtagsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(searchRepositoryProvider).getHashtags();
});

final genresProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(searchRepositoryProvider).getGenres();
});
