import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/app_theme.dart';
import '../models/song.dart';
import '../providers/lyrics_sync_provider.dart';
import '../screens/full_lyrics_screen.dart';

class LyricsPreviewCard extends ConsumerStatefulWidget {
  final Song song;

  const LyricsPreviewCard({super.key, required this.song});

  @override
  ConsumerState<LyricsPreviewCard> createState() => _LyricsPreviewCardState();
}

class _LyricsPreviewCardState extends ConsumerState<LyricsPreviewCard> {
  final ScrollController _previewScrollController = ScrollController();

  void _autoScrollToActive(int index) {
    if (_previewScrollController.hasClients && index >= 0) {
      // Small offset for card preview
      final double targetOffset = index * 32.0; 
      _previewScrollController.animateTo(
        targetOffset.clamp(0.0, _previewScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(lyricsDataProvider(widget.song));
    final activeIndex = ref.watch(currentLyricIndexProvider(widget.song));

    // Listen to index changes to scroll the mini preview
    ref.listen(currentLyricIndexProvider(widget.song), (prev, next) {
      _autoScrollToActive(next);
    });

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF4A5568).withOpacity(0.8), // Dark blue-grey from image
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bản xem trước lời bài hát',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => _navigateToFullLyrics(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'MỞ RỘNG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(LucideIcons.maximize2, size: 12, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            height: 120, // Height for ~4 lines
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: lyricsAsync.when(
              data: (data) {
                if (data.isEmpty) {
                  return _buildNoLyricsState();
                }
                
                return ListView.builder(
                  controller: _previewScrollController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.lines.length,
                  itemBuilder: (context, index) {
                    final line = data.lines[index];
                    final isActive = index == activeIndex;
                    
                    return AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white24,
                        fontSize: 16,
                        height: 2.0,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      ),
                      child: Text(line.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                    );
                  },
                );
              },
              loading: () {
                // Return 'No lyrics' state immediately while loading to ensure 
                // the user always sees a result without waiting.
                return _buildNoLyricsState();
              },
              error: (err, _) => _buildNoLyricsState(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ElevatedButton(
              onPressed: () => _navigateToFullLyrics(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                minimumSize: const Size(0, 36),
              ),
              child: const Text(
                'Hiện lời bài hát',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLyricsState() {
    return const Center(
      child: Text(
        'Chưa có lời bài hát cho ca khúc này',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _navigateToFullLyrics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FullLyricsScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}
