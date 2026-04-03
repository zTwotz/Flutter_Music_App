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
  final List<Map<String, dynamic>> genres;
  final List<Map<String, dynamic>> moods;
  final List<Map<String, dynamic>> hashtags;

  SearchResults({
    required this.songs,
    required this.artists,
    required this.albums,
    required this.playlists,
    required this.podcasts,
    required this.genres,
    required this.moods,
    required this.hashtags,
  });

  factory SearchResults.empty() => SearchResults(
        songs: [],
        artists: [],
        albums: [],
        playlists: [],
        podcasts: [],
        genres: [],
        moods: [],
        hashtags: [],
      );

  bool get isEmpty =>
      songs.isEmpty &&
      artists.isEmpty &&
      albums.isEmpty &&
      playlists.isEmpty &&
      podcasts.isEmpty &&
      genres.isEmpty &&
      moods.isEmpty &&
      hashtags.isEmpty;
}

// ─── Providers ───────────────────────────────────────────────────────────────

class SearchQueryNotifier extends Notifier<String> {
  Timer? _debounceTimer;

  @override
  String build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return '';
  }
  
  void setQuery(String query) {
    if (state == query) return;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      state = query;
    });
  }

  void setQueryImmediate(String query) {
    _debounceTimer?.cancel();
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final searchResultsProvider = FutureProvider<SearchResults>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return SearchResults.empty();

  final repo = ref.watch(searchRepositoryProvider);
  
  try {
    // Parallel execution of all search queries
    final results = await Future.wait([
      repo.searchSongs(query),
      repo.searchArtists(query),
      repo.searchAlbums(query),
      repo.searchPlaylists(query),
      repo.searchPodcasts(query),
      repo.searchGenres(query),
      repo.searchMoods(query),
      repo.searchHashtags(query),
    ]);

    return SearchResults(
      songs: results[0] as List<Song>,
      artists: results[1] as List<Artist>,
      albums: results[2] as List<Album>,
      playlists: results[3] as List<Playlist>,
      podcasts: results[4] as List<Podcast>,
      genres: results[5] as List<Map<String, dynamic>>,
      moods: results[6] as List<Map<String, dynamic>>,
      hashtags: results[7] as List<Map<String, dynamic>>,
    );
  } catch (e) {
    rethrow;
  }
});

final recentSearchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value?.session?.user;
  // pass user?.id which can be null for guest mode
  return ref.watch(searchRepositoryProvider).getRecentSearches(user?.id);
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

final moodsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(searchRepositoryProvider).getMoods();
});
