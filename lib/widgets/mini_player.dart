import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/player_provider.dart';
import '../core/app_theme.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final playerStateAsync = ref.watch(playbackStateProvider);
    final positionDataAsync = ref.watch(positionDataProvider);

    if (currentSong == null) return const SizedBox.shrink();

    final isPlaying = playerStateAsync.value?.playing ?? false;
    final positionData = positionDataAsync.value;
    
    double progress = 0.0;
    if (positionData != null && positionData.duration.inMilliseconds > 0) {
      progress = (positionData.position.inMilliseconds / positionData.duration.inMilliseconds).clamp(0.0, 1.0);
    }

    return GestureDetector(
      onTap: () => context.push('/player'),
      child: Container(
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.l),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceHighlight.withOpacity(0.8),
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                      child: Row(
                        children: [
                          // Cover Image
                          Hero(
                            tag: 'player-cover',
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppRadius.s),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.s),
                                child: currentSong.coverUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: currentSong.coverUrl!,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) => _buildPlaceholder(),
                                      )
                                    : _buildPlaceholder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          // Song Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentSong.title,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentSong.artistName ?? 'Nghệ sĩ',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Controls
                          IconButton(
                            icon: const Icon(LucideIcons.skipBack, size: 20),
                            onPressed: () => ref.read(audioHandlerProvider).skipToPrevious(),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isPlaying ? LucideIcons.pause : LucideIcons.play, 
                                size: 20, 
                                color: Colors.black,
                              ),
                              onPressed: () => ref.read(audioHandlerProvider).togglePlayPause(),
                            ),
                          ).animate(target: isPlaying ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(LucideIcons.skipForward, size: 20),
                            onPressed: () => ref.read(audioHandlerProvider).skipToNext(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                    child: Stack(
                      children: [
                        Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        AnimatedContainer(
                          duration: 500.ms,
                          height: 2.5,
                          width: (MediaQuery.of(context).size.width - 48) * progress,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 1.0, curve: Curves.easeOutQuart, duration: 600.ms);
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade900,
      child: const Icon(LucideIcons.music, color: Colors.white24, size: 20),
    );
  }
}
