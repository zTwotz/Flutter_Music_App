import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/app_theme.dart';

// ─── Category Card ───────────────────────────────────────────────────────────

class SearchCategoryCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final Color color;
  final VoidCallback onTap;

  const SearchCategoryCard({
    super.key,
    required this.title,
    this.imageUrl,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              right: -20,
              child: Transform.rotate(
                angle: 0.5,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(LucideIcons.music, size: 40, color: Colors.white24),
                      )
                    : const Icon(LucideIcons.music, size: 40, color: Colors.white24),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search Result Tile ──────────────────────────────────────────────────────

class SearchResultTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String type; // 'song', 'artist', 'album', 'playlist', 'podcast'
  final VoidCallback onTap;

  const SearchResultTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(type == 'artist' ? 24 : 4),
          color: AppTheme.surfaceHighlight,
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _buildIcon(),
              )
            : _buildIcon(),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$type • $subtitle',
        style: const TextStyle(color: AppTheme.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    switch (type) {
      case 'artist':
        icon = LucideIcons.users;
        break;
      case 'playlist':
        icon = LucideIcons.listMusic;
        break;
      case 'album':
        icon = LucideIcons.disc;
        break;
      case 'podcast':
        icon = LucideIcons.radio;
        break;
      default:
        icon = LucideIcons.music;
    }
    return Icon(icon, size: 24, color: Colors.white54);
  }
}

// ─── Hashtag Chip ───────────────────────────────────────────────────────────

class HashtagChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const HashtagChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHighlight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          '#$label',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
