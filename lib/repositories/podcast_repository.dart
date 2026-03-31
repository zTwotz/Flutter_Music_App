import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/podcast.dart';
import '../models/podcast_channel.dart';

class PodcastRepository {
  final SupabaseClient _supabase;

  PodcastRepository(this._supabase);

  Future<List<Podcast>> fetchAllPodcasts() async {
    final response = await _supabase
        .from('podcasts')
        .select('*, podcast_channels(*)')
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(20);

    return (response as List).map((row) => Podcast.fromJson(row)).toList();
  }

  Future<List<PodcastChannel>> fetchSubscribedChannels(String userId) async {
    final response = await _supabase
        .from('channel_subscriptions')
        .select('channel_id, podcast_channels(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .where((row) => row['podcast_channels'] != null)
        .map((row) => PodcastChannel.fromJson(row['podcast_channels']))
        .toList();
  }

  Future<List<Podcast>> fetchPodcastsByChannel(String channelId) async {
    final response = await _supabase
        .from('podcasts')
        .select('*, podcast_channels(*)')
        .eq('channel_id', channelId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List).map((row) => Podcast.fromJson(row)).toList();
  }

  Future<PodcastChannel> getChannelDetail(String channelId) async {
    final response = await _supabase
        .from('podcast_channels')
        .select()
        .eq('id', channelId)
        .single();
    return PodcastChannel.fromJson(response);
  }

  Future<bool> checkIsSubscribed(String userId, String channelId) async {
    final response = await _supabase
        .from('channel_subscriptions')
        .select('id')
        .eq('user_id', userId)
        .eq('channel_id', channelId)
        .maybeSingle();
    return response != null;
  }

  Future<void> toggleSubscription(String userId, String channelId, bool isSubscribed) async {
    if (isSubscribed) {
      await _supabase.from('channel_subscriptions').delete().match({
        'user_id': userId,
        'channel_id': channelId,
      });
      // Optional: RPC for decrementing subscriber count cache
      await _supabase.rpc('decrement_channel_subscribers', params: {'channel_id_param': channelId}).catchError((_) {});
    } else {
      await _supabase.from('channel_subscriptions').insert({
        'user_id': userId,
        'channel_id': channelId,
      });
      // Optional: RPC for incrementing subscriber count cache
      await _supabase.rpc('increment_channel_subscribers', params: {'channel_id_param': channelId}).catchError((_) {});
    }
  }

  Future<List<Podcast>> fetchLatestPodcastsFromSubscriptions(String userId) async {
    // This is more complex, fetch podcasts where channel_id is in subscriptions
    // For simplicity, we fetch all subscribed channel IDs first
    final subs = await _supabase
        .from('channel_subscriptions')
        .select('channel_id')
        .eq('user_id', userId);
    
    final channelIds = (subs as List).map((row) => row['channel_id'] as String).toList();
    if (channelIds.isEmpty) return [];

    final response = await _supabase
        .from('podcasts')
        .select('*, podcast_channels(*)')
        .inFilter('channel_id', channelIds)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(30);

    return (response as List).map((row) => Podcast.fromJson(row)).toList();
  }
}
