import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/app_theme.dart';
import '../providers/library_providers.dart';
import '../providers/player_provider.dart';
import '../widgets/song_list_item.dart';
import '../core/app_ui_utils.dart';
import '../core/player_utils.dart';

class LikedSongsScreen extends ConsumerWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedAsync = ref.watch(likedSongsProvider);

    return Material(
      color: AppTheme.background,
      child: CustomScrollView(
        slivers: [
          // ── Gradient Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF4B2A8C),
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Bài hát đã thích',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6B35CF), Color(0xFF1A1A2E)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9B59B6), Color(0xFFE91E8C)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.heart, color: Colors.white, size: 40),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Action Row ──────────────────────────────────────────────────
          likedAsync.when(
            data: (songs) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${songs.length} bài hát',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (songs.isNotEmpty) ...[
                      _buildCircleAction(
                        icon: LucideIcons.shuffle,
                        onTap: () {
                          if (songs.isEmpty) return;
                          final shuffled = List.of(songs)..shuffle();
                          context.playOrNavigate(ref, shuffled.first, shuffled);
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildPlayButton(onTap: () {
                        if (songs.isEmpty) return;
                        context.playOrNavigate(ref, songs.first, songs);
                      }),
                    ],
                  ],
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: SizedBox()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
          ),

          // ── Song List ────────────────────────────────────────────────────
          likedAsync.when(
            data: (songs) {
              if (songs.isEmpty) {
                return const SliverFillRemaining(
                  child: _EmptyLikedSongs(),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = songs[index];
                    return SongListItem(
                      song: song,
                      onTap: () {
                        context.playOrNavigate(ref, song, songs, initialIndex: index);
                      },
                    );
                  },
                  childCount: songs.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Lỗi: $e')),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildPlayButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF1DB954), Color(0xFF1AA34A)],
          ),
        ),
        child: const Icon(LucideIcons.play, color: Colors.black, size: 22),
      ),
    );
  }

  Widget _buildCircleAction({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _EmptyLikedSongs extends StatelessWidget {
  const _EmptyLikedSongs();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.heart, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            'Chưa có bài hát nào',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhấn ♥ trên bất kỳ bài hát nào\nđể thêm vào đây',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
