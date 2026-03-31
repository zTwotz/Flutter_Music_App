import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/song.dart';
import '../providers/favorite_provider.dart';
import '../core/app_theme.dart';

class SongListItem extends ConsumerWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;
  final Widget? trailing;

  const SongListItem({
    super.key,
    required this.song,
    required this.onTap,
    this.onMoreTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLikedAsync = ref.watch(isLikedProvider(song.id));

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: song.coverUrl != null
            ? CachedNetworkImage(
                imageUrl: song.coverUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
      title: Text(
        song.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artistName ?? 'Unknown Artist',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isLikedAsync.when(
                data: (isLiked) => IconButton(
                  icon: Icon(
                    isLiked ? LucideIcons.heart : LucideIcons.heart,
                    fill: isLiked ? 1 : 0,
                    color: isLiked ? AppTheme.primary : AppTheme.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => ref.read(favoriteNotifierProvider.notifier).toggleLike(context, song.id, isLiked),
                ),
                loading: () => const SizedBox(width: 48, height: 48, child: Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, __) => const SizedBox.shrink(),
              ),
              if (onMoreTap != null)
                IconButton(
                  icon: const Icon(LucideIcons.moreVertical, size: 20),
                  onPressed: onMoreTap,
                ),
            ],
          ),
      onTap: onTap,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.grey.shade800,
      child: const Icon(LucideIcons.music, color: Colors.white54),
    );
  }
}
