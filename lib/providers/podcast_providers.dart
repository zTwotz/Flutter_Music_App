import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/podcast.dart';
import '../models/podcast_channel.dart';
import '../repositories/podcast_repository.dart';
import '../providers/supabase_provider.dart';
import '../providers/auth_provider.dart';
import '../core/guest_guard.dart';

final allPodcastsProvider = FutureProvider<List<Podcast>>((ref) async {
  return ref.watch(podcastRepositoryProvider).fetchAllPodcasts();
});

final subscribedChannelsProvider = FutureProvider<List<PodcastChannel>>((ref) async {
  final user = ref.watch(authStateProvider).value?.session?.user;
  if (user == null) return [];
  return ref.watch(podcastRepositoryProvider).fetchSubscribedChannels(user.id);
});

final followedPodcastsProvider = FutureProvider<List<Podcast>>((ref) async {
  final user = ref.watch(authStateProvider).value?.session?.user;
  if (user == null) return [];
  return ref.watch(podcastRepositoryProvider).fetchLatestPodcastsFromSubscriptions(user.id);
});

final channelDetailProvider = FutureProvider.family<PodcastChannel, String>((ref, id) async {
  return ref.watch(podcastRepositoryProvider).getChannelDetail(id);
});

final channelPodcastsProvider = FutureProvider.family<List<Podcast>, String>((ref, id) async {
  return ref.watch(podcastRepositoryProvider).fetchPodcastsByChannel(id);
});

final isSubscribedProvider = FutureProvider.family<bool, String>((ref, channelId) async {
  final user = ref.watch(authStateProvider).value?.session?.user;
  if (user == null) return false;
  return ref.watch(podcastRepositoryProvider).checkIsSubscribed(user.id, channelId);
});

class PodcastSubscriptionNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggleSubscription(BuildContext context, String channelId, bool currentStatus) async {
    if (!GuestGuard.ensureAuthenticated(context, ref, message: 'Vui lòng đăng nhập để theo dõi kênh podcast.')) return;

    final user = ref.read(authStateProvider).value?.session?.user;
    if (user == null) return;

    await ref.read(podcastRepositoryProvider).toggleSubscription(user.id, channelId, currentStatus);
    
    // Invalidate relevant providers to refresh UI
    ref.invalidate(isSubscribedProvider(channelId));
    ref.invalidate(subscribedChannelsProvider);
    ref.invalidate(followedPodcastsProvider);
    ref.invalidate(channelDetailProvider(channelId));
  }
}

final podcastSubscriptionNotifierProvider = NotifierProvider<PodcastSubscriptionNotifier, void>(
  PodcastSubscriptionNotifier.new,
);
