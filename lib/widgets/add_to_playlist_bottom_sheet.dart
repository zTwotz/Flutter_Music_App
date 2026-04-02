import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_provider.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../core/app_theme.dart';
import '../core/guest_guard.dart';

class AddToPlaylistBottomSheet extends ConsumerWidget {
  final Song song;

  const AddToPlaylistBottomSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value?.session?.user;
    
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.lock, size: 48, color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text('Đăng nhập để lưu playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Hãy đăng nhập để có thể tạo và quản lý danh sách phát của riêng bạn.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Redirect to login
              },
              child: const Text('Đăng nhập ngay'),
            ),
          ],
        ),
      );
    }

    final playlistsAsync = ref.watch(_userPlaylistsProvider(user.id));

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Thêm vào danh sách phát', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Flexible(
            child: playlistsAsync.when(
              data: (playlists) => playlists.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return ListTile(
                          leading: const Icon(LucideIcons.music, color: AppTheme.primary),
                          title: Text(playlist.name),
                          subtitle: const Text('Nhấn để thêm vào danh sách này'),
                          onTap: () async {
                            try {
                              await ref.read(playlistRepositoryProvider).addSongsToPlaylist(playlist.id, [song.id]);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã thêm vào ${playlist.name}')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e')),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
              loading: () => const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
              error: (e, _) => Padding(padding: EdgeInsets.all(32), child: Text('Lỗi: $e')),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const Icon(LucideIcons.plusCircle, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('Bạn chưa có danh sách phát nào', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

final _userPlaylistsProvider = FutureProvider.family<List<Playlist>, String>((ref, userId) async {
  return ref.watch(playlistRepositoryProvider).fetchUserOwnedPlaylists(userId);
});

void showAddToPlaylist(BuildContext context, WidgetRef ref, Song song) {
  if (!GuestGuard.ensureAuthenticated(context, ref)) return;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddToPlaylistBottomSheet(song: song),
  );
}
