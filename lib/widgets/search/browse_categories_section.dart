import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BrowseCategoriesSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>>? categoriesData;
  final Function(String) onCategoryTap;

  const BrowseCategoriesSection({
    super.key, 
    required this.title,
    this.categoriesData,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    // Premium, vibrant card colors
    final List<Color> cardColors = [
      const Color(0xFFE8115B), // Pop
      const Color(0xFF148A08), // Rap
      const Color(0xFF8D67AB), // Indie
      const Color(0xFFE13300), // Chill
      const Color(0xFF7358FF), // Sad
      const Color(0xFF1E3264), // Focus
      const Color(0xFFAF2896), // Podcast
      const Color(0xFF509BF5), // New
      const Color(0xFFBA5D07), // Featured
      const Color(0xFF477D95), // Tags
    ];

    // Filter categories that have images first
    List<Map<String, dynamic>> items = [];
    if (categoriesData != null && categoriesData!.isNotEmpty) {
      for (int i = 0; i < categoriesData!.length; i++) {
        final item = categoriesData![i];
        items.add({
          'title': item['name'] ?? 'Danh mục',
          'color': cardColors[i % cardColors.length],
          'imageUrl': item['cover_url'],
        });
      }
    } else {
      // High-quality fallback items
      items = [
        {'title': 'Pop', 'color': cardColors[0]},
        {'title': 'Rap', 'color': cardColors[1]},
        {'title': 'Indie', 'color': cardColors[2]},
        {'title': 'Chill', 'color': cardColors[3]},
        {'title': 'Buồn', 'color': cardColors[4]},
        {'title': 'Tập trung', 'color': cardColors[5]},
        {'title': 'Podcast', 'color': cardColors[6]},
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              if (items.length > 6)
                TextButton(
                  onPressed: () {},
                  child: const Text('Hiện thêm', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6, 
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final cat = items[index];
              return _buildCategoryCard(
                title: cat['title'] as String,
                color: cat['color'] as Color,
                imageUrl: cat['imageUrl'] as String?,
                onTap: () => onCategoryTap(cat['title'] as String),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required Color color,
    String? imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image (Full Coverage)
            if (imageUrl != null && imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl, 
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(color: color),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.6)],
                  ),
                ),
              ),

            // Subtle Gradient Overlay for Text Readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Title
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                  shadows: [
                    Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
