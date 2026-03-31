import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_provider.dart';
import '../providers/library_providers.dart';
import '../core/guest_guard.dart';

final artistDetailProvider = FutureProvider.family<Artist, String>((ref, id) async {
  return ref.read(artistRepositoryProvider).getArtistDetail(id);
});

final artistSongsProvider = FutureProvider.family<List<Song>, String>((ref, id) async {
  return ref.read(artistRepositoryProvider).getArtistSongs(id);
});

final artistAlbumsProvider = FutureProvider.family<List<Album>, String>((ref, id) async {
  return ref.read(artistRepositoryProvider).getArtistAlbums(id);
});

final artistFollowStatusProvider = FutureProvider.family<bool, String>((ref, id) async {
  final user = ref.watch(authStateProvider).value?.session?.user;
  if (user == null) return false;
  return ref.watch(followRepositoryProvider).isArtistFollowed(user.id, id);
});

class ArtistFollowNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggleFollow(BuildContext context, String artistId, bool currentStatus) async {
    if (!GuestGuard.ensureAuthenticated(context, ref, message: 'Vui lòng đăng nhập để theo dõi nghệ sĩ.')) return;

    final user = ref.read(authStateProvider).value?.session?.user;
    if (user == null) return;
    
    // Toggle follow status
    await ref.read(followRepositoryProvider).toggleFollow(user.id, artistId, currentStatus);
    
    // Invalidate follow status to trigger UI rebuild
    ref.invalidate(artistFollowStatusProvider(artistId));
    ref.invalidate(artistDetailProvider(artistId));
    // Refresh library followed artists
    ref.invalidate(followedArtistsLibraryProvider);
  }
}

final artistFollowNotifierProvider = NotifierProvider<ArtistFollowNotifier, void>(
  ArtistFollowNotifier.new,
);
