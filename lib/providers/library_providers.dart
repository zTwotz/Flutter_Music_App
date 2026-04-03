import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../models/artist.dart';
import '../models/podcast_channel.dart';
import 'supabase_provider.dart';
import 'auth_provider.dart';

// ─── Liked Songs ──────────────────────────────────────────────────────────────

final likedSongsProvider = FutureProvider<List<Song>>((ref) async {
  final user = ref.watch(authStateProvider).value?.session?.user;
  if (user == null) return [];
  return ref.watch(favoriteRepositoryProvider).fetchLikedSongs(user.id);
});

final likedSongsCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authStateProvider).value?.session?.user;
  if (user == null) return 0;
  return ref.watch(favoriteRepositoryProvider).getLikedSongsCount(user.id);
});

// ─── User-created Playlists ───────────────────────────────────────────────────

class UserPlaylistsNotifier extends AsyncNotifier<List<Playlist>> {
  @override
  Future<List<Playlist>> build() async {
    final user = ref.watch(authStateProvider).value?.session?.user;
    if (user == null) return [];
    return ref.watch(playlistRepositoryProvider).fetchUserOwnedPlaylists(user.id);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final userPlaylistsProvider =
    AsyncNotifierProvider<UserPlaylistsNotifier, List<Playlist>>(
  UserPlaylistsNotifier.new,
);

// ─── Saved (Bookmarked) Playlists ─────────────────────────────────────────────

final savedPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final user = ref.watch(authStateProvider).value?.session?.user;
  if (user == null) return [];
  return ref.watch(collectionRepositoryProvider).fetchSavedPlaylists(user.id);
});

// ─── Followed Artists ─────────────────────────────────────────────────────────

final followedArtistsLibraryProvider = FutureProvider<List<Artist>>((ref) async {
  final user = ref.watch(authStateProvider).value?.session?.user;
  if (user == null) return [];
  return ref.watch(followRepositoryProvider).fetchFollowedArtists(user.id);
});

// ─── Subscribed Podcast Channels ─────────────────────────────────────────────

final subscribedChannelsLibraryProvider = FutureProvider<List<PodcastChannel>>((ref) async {
  final user = ref.watch(authStateProvider).value?.session?.user;
  if (user == null) return [];
  return ref.watch(podcastRepositoryProvider).fetchSubscribedChannels(user.id);
});

// ─── Library Filter ───────────────────────────────────────────────────────────

enum LibraryFilter { all, playlists, artists, podcasts, downloads }

class LibraryFilterNotifier extends Notifier<LibraryFilter> {
  @override
  LibraryFilter build() => LibraryFilter.all;
  void setFilter(LibraryFilter f) => state = f;
}

final libraryFilterProvider = NotifierProvider<LibraryFilterNotifier, LibraryFilter>(
  LibraryFilterNotifier.new,
);
