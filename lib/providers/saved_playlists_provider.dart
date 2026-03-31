import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_provider.dart';
import '../providers/library_providers.dart';

final isPlaylistSavedProvider = FutureProvider.family<bool, int>((ref, playlistId) async {
  final user = ref.watch(authStateProvider).value?.session?.user;
  if (user == null) return false;
  return ref.watch(collectionRepositoryProvider).isPlaylistSaved(user.id, playlistId);
});

class SavedPlaylistNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggleSave(int playlistId, bool currentStatus) async {
    final user = ref.read(authStateProvider).value?.session?.user;
    if (user == null) return;

    await ref.read(collectionRepositoryProvider).toggleSavePlaylist(user.id, playlistId, currentStatus);
    ref.invalidate(isPlaylistSavedProvider(playlistId));
    ref.invalidate(savedPlaylistsProvider);
  }
}

final savedPlaylistNotifierProvider = NotifierProvider<SavedPlaylistNotifier, void>(SavedPlaylistNotifier.new);
