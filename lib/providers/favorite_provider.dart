import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_provider.dart';
import '../providers/library_providers.dart';
import '../core/guest_guard.dart';

final isLikedProvider = FutureProvider.family<bool, int>((ref, songId) async {
  final user = ref.watch(authStateProvider).value?.session?.user;
  if (user == null) return false;
  return ref.watch(favoriteRepositoryProvider).isSongLiked(user.id, songId);
});

class FavoriteNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggleLike(BuildContext context, int songId, bool currentStatus) async {
    if (!GuestGuard.ensureAuthenticated(context, ref)) return;

    final user = ref.read(authStateProvider).value?.session?.user;
    if (user == null) return;

    await ref.read(favoriteRepositoryProvider).toggleLike(user.id, songId, currentStatus);
    ref.invalidate(isLikedProvider(songId));
    ref.invalidate(likedSongsProvider);
    ref.invalidate(likedSongsCountProvider);
  }
}

final favoriteNotifierProvider = NotifierProvider<FavoriteNotifier, void>(FavoriteNotifier.new);
