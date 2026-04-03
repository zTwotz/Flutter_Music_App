import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';

import 'search_state_widgets.dart';

class RecentSearchSection extends StatelessWidget {
  final List<dynamic> recentSearches;
  final VoidCallback onClearHistory;
  final Function(Map<String, dynamic>) onSearchItemTap;
  final Function(Map<String, dynamic>)? onDeleteItem;

  const RecentSearchSection({
    super.key,
    required this.recentSearches,
    required this.onClearHistory,
    required this.onSearchItemTap,
    this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    if (recentSearches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: SearchEmptyState(
          title: 'Khơi nguồn cảm hứng',
          subtitle: 'Tìm kiếm nghệ sĩ, bài hát hoặc podcast bạn yêu thích.',
          icon: LucideIcons.headphones,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tìm kiếm gần đây',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: onClearHistory,
                child: const Text(
                  'Xóa lịch sử',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentSearches.length,
          itemBuilder: (context, index) {
            final item = recentSearches[index];
            final keyword = item['keyword'] as String?;
            final title = item['title'] as String?;
            final subtitle = item['subtitle'] as String?;
            final imageUrl = item['image_url'] as String?;
            final contentType = item['content_type'] as String;

            // Determine what to display
            final displayTitle = title ?? keyword ?? '';
            final displaySubtitle = subtitle ?? (contentType == 'keyword' ? 'Tìm kiếm' : contentType);

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: contentType == 'artist' ? BorderRadius.circular(24) : BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (ctx, _, __) => _buildFallbackIcon(contentType))
                    : _buildFallbackIcon(contentType),
              ),
              title: Text(
                displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                displaySubtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white54, size: 20),
                onPressed: () {
                  if (onDeleteItem != null) {
                    onDeleteItem!(item); // Assuming we change onDeleteItem to accept dynamic map
                  }
                },
              ),
              onTap: () {
                // If it's a keyword, we put in search bar. Otherwise navigate.
                onSearchItemTap(item);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFallbackIcon(String contentType) {
    IconData icon;
    switch (contentType) {
      case 'song': icon = LucideIcons.music; break;
      case 'artist': icon = LucideIcons.user; break;
      case 'album': icon = LucideIcons.disc; break;
      case 'playlist': icon = LucideIcons.listMusic; break;
      case 'podcast': icon = LucideIcons.mic; break;
      default: icon = LucideIcons.history; break;
    }
    return Icon(icon, color: Colors.white70, size: 20);
  }
}
