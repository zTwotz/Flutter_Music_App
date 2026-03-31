import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/podcast.dart';
import '../core/app_theme.dart';

class PodcastListItem extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const PodcastListItem({
    super.key,
    required this.podcast,
    required this.onTap,
    this.onMoreTap,
  });

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    if (m < 60) return '$m phút';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? '${h}g ${rem}p' : '${h}g';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: podcast.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: podcast.coverUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 12),
            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    podcast.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    podcast.channelName ?? 'Podcast',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (podcast.durationSeconds > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.clock, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(podcast.durationSeconds),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
            // More button
            IconButton(
              icon: const Icon(LucideIcons.moreVertical, size: 20, color: AppTheme.textSecondary),
              onPressed: onMoreTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(LucideIcons.radio, color: Colors.white38, size: 26),
    );
  }
}
