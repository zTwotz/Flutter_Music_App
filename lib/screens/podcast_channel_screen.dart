import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../models/podcast_channel.dart';
import '../providers/podcast_providers.dart';
import '../providers/player_provider.dart';
import '../widgets/state_widgets.dart';
import '../core/app_theme.dart';
import '../core/app_ui_utils.dart';
import '../widgets/podcast_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PodcastChannelScreen extends ConsumerWidget {
  final String channelId;

  const PodcastChannelScreen({super.key, required this.channelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelAsync = ref.watch(channelDetailProvider(channelId));
    final episodesAsync = ref.watch(channelPodcastsProvider(channelId));
    final isSubscribedAsync = ref.watch(isSubscribedProvider(channelId));
    
    final isSubscribed = isSubscribedAsync.value ?? false;
    final isSubLoading = isSubscribedAsync.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: channelAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (err, _) => AppErrorState(
          error: err.toString(),
          onRetry: () => ref.invalidate(channelDetailProvider(channelId)),
        ),
        data: (channel) => CustomScrollView(
          slivers: [
            // ── Sliver App Bar with Banner/Avatar ──
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: AppTheme.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Simple gradient or banner if available
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.indigo, AppTheme.background],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppTheme.surfaceHighlight,
                            backgroundImage: channel.avatarUrl != null 
                                ? CachedNetworkImageProvider(channel.avatarUrl!) 
                                : null,
                            child: channel.avatarUrl == null 
                                ? const Icon(LucideIcons.mic, size: 30, color: Colors.white24) 
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  channel.name,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.1),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${channel.subscriberCount} người đăng ký',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Section Actions (Subscribe) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSubLoading 
                          ? null 
                          : () => ref.read(podcastSubscriptionNotifierProvider.notifier)
                              .toggleSubscription(context, channelId, isSubscribed),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSubscribed ? AppTheme.surfaceHighlight : AppTheme.primary,
                          foregroundColor: isSubscribed ? AppTheme.textPrimary : Colors.black,
                          minimumSize: const Size(0, 44),
                        ),
                        child: Text(isSubscribed ? 'Đang theo dõi' : 'Theo dõi'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(LucideIcons.share2, size: 20),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.bell, size: 20),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text('Tất cả tập podcast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            // ── Episodes List ──
            episodesAsync.when(
              loading: () => const SliverToBoxAdapter(child: AppLoadingIndicator()),
              error: (err, _) => SliverToBoxAdapter(
                child: AppErrorState(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(channelPodcastsProvider(channelId)),
                ),
              ),
              data: (podcasts) {
                if (podcasts.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: LucideIcons.micOff,
                      title: 'Chưa có tập nào',
                      message: 'Kênh này hiện chưa đăng bản tin nào.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return PodcastCard(
                          podcast: podcasts[index],
                          onTap: () => context.push('/podcast/${podcasts[index].id}', extra: podcasts[index]),
                        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
                      },
                      childCount: podcasts.length,
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}
