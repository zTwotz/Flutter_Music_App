import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'supabase_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class CreatePlaylistState {
  final int step; // 1 or 2
  final String name;
  final String description;
  final List<Song> selectedSongs;
  final List<Song> allSongs;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const CreatePlaylistState({
    this.step = 1,
    this.name = '',
    this.description = '',
    this.selectedSongs = const [],
    this.allSongs = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  CreatePlaylistState copyWith({
    int? step,
    String? name,
    String? description,
    List<Song>? selectedSongs,
    List<Song>? allSongs,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CreatePlaylistState(
      step: step ?? this.step,
      name: name ?? this.name,
      description: description ?? this.description,
      selectedSongs: selectedSongs ?? this.selectedSongs,
      allSongs: allSongs ?? this.allSongs,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Songs filtered by current searchQuery (client-side)
  List<Song> get filteredSongs {
    if (searchQuery.isEmpty) return allSongs;
    final q = searchQuery.toLowerCase();
    return allSongs.where((s) {
      return s.title.toLowerCase().contains(q) ||
          (s.artistName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  bool isSongSelected(int songId) => selectedSongs.any((s) => s.id == songId);
}

// ─── Notifier (Riverpod 3.x) ──────────────────────────────────────────────────

class CreatePlaylistNotifier extends Notifier<CreatePlaylistState> {
  @override
  CreatePlaylistState build() => const CreatePlaylistState();

  void setName(String v) => state = state.copyWith(name: v);
  void setDescription(String v) => state = state.copyWith(description: v);

  void goToStep2() => state = state.copyWith(step: 2);
  void goToStep1() => state = state.copyWith(step: 1);

  void setSearchQuery(String q) => state = state.copyWith(searchQuery: q);

  void toggleSong(Song song) {
    final isSelected = state.isSongSelected(song.id);
    final updated = isSelected
        ? state.selectedSongs.where((s) => s.id != song.id).toList()
        : [...state.selectedSongs, song];
    state = state.copyWith(selectedSongs: updated);
  }

  void removeSong(int songId) {
    final updated = state.selectedSongs.where((s) => s.id != songId).toList();
    state = state.copyWith(selectedSongs: updated);
  }

  /// Load the full song catalogue for the picker
  Future<void> loadSongs() async {
    try {
      final songs = await ref.read(songRepositoryProvider).fetchAllSongs();
      state = state.copyWith(allSongs: songs);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Save the playlist + songs to Supabase. Returns the created Playlist or null on error.
  Future<Playlist?> save(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final playlist = await ref.read(playlistRepositoryProvider).createPlaylist(
        userId: userId,
        name: state.name.trim(),
        description: state.description.trim().isEmpty ? null : state.description.trim(),
        songIds: state.selectedSongs.map((s) => s.id).toList(),
      );
      state = state.copyWith(isLoading: false);
      return playlist;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void reset() => state = const CreatePlaylistState();
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final createPlaylistProvider =
    NotifierProvider.autoDispose<CreatePlaylistNotifier, CreatePlaylistState>(
  CreatePlaylistNotifier.new,
);
