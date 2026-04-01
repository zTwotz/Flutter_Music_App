import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../models/podcast.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../core/app_theme.dart';
import '../core/app_ui_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PodcastDetailScreen extends ConsumerWidget {
  final Podcast podcast;

  const PodcastDetailScreen({super.key, required this.podcast});

  Song _toSong(Podcast p) {
    return Song(
      id: p.id.hashCode,
      title: p.title,
      artistName: p.channelName ?? 'Podcast',
      coverUrl: p.coverUrl,
      audioUrl: p.audioUrl ?? '',
      durationSeconds: p.durationSeconds,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppTheme.surfaceHighlight,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (podcast.coverUrl != null)
                    CachedNetworkImage(
                      imageUrl: podcast.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceHighlight),
                    )
                  else
                    Container(color: AppTheme.surfaceHighlight),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.background],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    podcast.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ).animate().fadeIn(duration: 600.ms),
                  const SizedBox(height: AppSpacing.s),
                  GestureDetector(
                    onTap: () {
                      if (podcast.channelId != null) {
                        context.pushSafe('/podcast-channel/${podcast.channelId}');
                      }
                    },
                    child: Row(
                      children: [
                        if (podcast.channelAvatarUrl != null)
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: CachedNetworkImageProvider(podcast.channelAvatarUrl!),
                          ),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          podcast.channelName ?? 'Kênh Podcast',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.primary),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: AppSpacing.l),
                  const SizedBox(height: AppSpacing.l),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (podcast.audioUrl != null && podcast.audioUrl!.isNotEmpty) {
                            final s = _toSong(podcast);
                            ref.read(currentSongProvider.notifier).setSong(s);
                            await ref.read(audioHandlerProvider).playSong(s);
                            if (context.mounted) context.pushSafe('/player');
                          }
                        },
                        icon: const Icon(LucideIcons.play, size: 20),
                        label: const Text('Phát ngay'),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      IconButton(
                        icon: const Icon(LucideIcons.heart),
                        onPressed: () => context.showInfo('Sắp ra mắt'),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.share2),
                        onPressed: () => context.showInfo('Sắp ra mắt'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Giới thiệu nội dung', 
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    podcast.description ?? 'Tập này hiện chưa có nội dung giới thiệu.',
                    style: const TextStyle(color: AppTheme.textSecondary, height: 1.6, fontSize: 15),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
