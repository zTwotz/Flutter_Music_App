import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/artist.dart';
import '../providers/artist_detail_provider.dart';
import '../widgets/song_list_item.dart';
import '../widgets/state_widgets.dart';
import '../core/app_theme.dart';
import '../core/player_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

String _formatNumber(int num) {
  if (num >= 1000000) {
    return '${(num / 1000000).toStringAsFixed(1)}M';
  } else if (num >= 1000) {
    return '${(num / 1000).toStringAsFixed(1)}K';
  }
  return num.toString();
}

class ArtistDetailScreen extends ConsumerWidget {
  final Artist artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistDetailAsync = ref.watch(artistDetailProvider(artist.id));
    final displayArtist = artistDetailAsync.value ?? artist;

    final songsAsync = ref.watch(artistSongsProvider(artist.id));
    
    final isFollowingAsync = ref.watch(artistFollowStatusProvider(artist.id));
    final isFollowing = isFollowingAsync.value ?? false;
    final isFollowLoading = isFollowingAsync.isLoading;

    final imageToUse = displayArtist.coverUrl ?? displayArtist.avatarUrl;

    return Material(
      color: AppTheme.background,
      child: CustomScrollView(
        slivers: [
          // ── Hero Header ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.surface,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageToUse != null)
                    CachedNetworkImage(
                      imageUrl: imageToUse,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildAvatarFallback(displayArtist),
                    )
                  else
                    _buildAvatarFallback(displayArtist),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.background],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: AppSpacing.m,
                    left: AppSpacing.m,
                    right: AppSpacing.m,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (displayArtist.monthlyListeners > 0)
                          Text(
                            '${_formatNumber(displayArtist.monthlyListeners)} người nghe hàng tháng',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                          ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 4),
                        Text(
                          displayArtist.name,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                        if (displayArtist.isVerified) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Icon(LucideIcons.checkCircle, color: Colors.blueAccent, size: 16),
                              SizedBox(width: 4),
                              Text('Nghệ sĩ đã xác minh', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ).animate().fadeIn(delay: 400.ms),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Action Row ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Play button requires songs to be loaded
                  songsAsync.when(
                    data: (songs) => Expanded(
                      child: ElevatedButton.icon(
                        onPressed: songs.isEmpty ? null : () {
                          context.playOrNavigate(ref, songs.first, songs);
                        },
                        icon: const Icon(LucideIcons.play, size: 18),
                        label: const Text('Phát nhạc'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                    loading: () => const Expanded(child: SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))),
                    error: (_, __) => const Expanded(child: SizedBox(height: 48)),
                  ),
                  const SizedBox(width: 12),
                  // Follow button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isFollowLoading ? null : () => ref.read(artistFollowNotifierProvider.notifier).toggleFollow(context, artist.id, isFollowing),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isFollowing ? AppTheme.textSecondary : AppTheme.textPrimary,
                        side: BorderSide(color: isFollowing ? AppTheme.textSecondary : AppTheme.textSecondary),
                        minimumSize: const Size(0, 48),
                      ),
                      child: isFollowLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bio and Followers Info ──
          if (displayArtist.bio != null || displayArtist.followersCount > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (displayArtist.followersCount > 0)
                      Text(
                        '${_formatNumber(displayArtist.followersCount)} Người theo dõi',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    if (displayArtist.bio != null && displayArtist.bio!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        displayArtist.bio!,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

          SliverToBoxAdapter(child: const SizedBox(height: 16)),

          // ── Popular Songs Section ──
          songsAsync.when(
            data: (songs) {
              if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
              return SliverMainAxisGroup(
                slivers: [
                   SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.l, AppSpacing.m, AppSpacing.s),
                      child: Text(
                        'Tất cả bài hát',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = songs[index];
                        return SongListItem(
                          song: song,
                          onTap: () {
                            context.playOrNavigate(ref, song, songs, initialIndex: index);
                          },
                        ).animate().fadeIn(delay: (index * 20).ms).slideX(begin: 0.05);
                      },
                      childCount: songs.length,
                    ),
                  ),
                ],
              );
            },
            loading: () => const SliverToBoxAdapter(child: AppLoadingIndicator()),
            error: (err, _) => SliverToBoxAdapter(
              child: AppErrorState(
                error: err.toString(),
                onRetry: () => ref.invalidate(artistSongsProvider(artist.id)),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)), // Mini player padding
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(Artist a) {
    final firstLetter = a.name.isNotEmpty ? a.name[0].toUpperCase() : 'A';
    return Container(
      color: AppTheme.surface,
      child: Center(
        child: Text(firstLetter, style: const TextStyle(fontSize: 80, color: Colors.white12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
