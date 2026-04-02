import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/podcast_channel.dart';
import '../core/app_theme.dart';

class FollowedPodcastChannelsRow extends StatelessWidget {
  final List<PodcastChannel> channels;

  const FollowedPodcastChannelsRow({super.key, required this.channels});

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 104,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          return GestureDetector(
            onTap: () => context.push('/podcast-channel/${channel.id}'),
            child: Container(
              width: 76,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.surfaceHighlight,
                    backgroundImage: channel.avatarUrl != null 
                        ? CachedNetworkImageProvider(channel.avatarUrl!) 
                        : null,
                    child: channel.avatarUrl == null
                        ? Text(
                            channel.name.isNotEmpty ? channel.name[0].toUpperCase() : 'P',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white60),
                          )
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    channel.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
