import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/app_theme.dart';
import '../providers/player_provider.dart';
import '../providers/lyrics_sync_provider.dart';
import '../widgets/progress_bar.dart';

class FullLyricsScreen extends ConsumerStatefulWidget {
  const FullLyricsScreen({super.key});

  @override
  ConsumerState<FullLyricsScreen> createState() => _FullLyricsScreenState();
}

class _FullLyricsScreenState extends ConsumerState<FullLyricsScreen> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToActive(int index) {
    if (_scrollController.hasClients && index >= 0) {
      // Calculate scroll to keep active line ~1/3 down the screen
      final double targetOffset = (index * 72.0) - (MediaQuery.of(context).size.height * 0.25);
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider);
    if (currentSong == null) return const Scaffold();

    final lyricsAsync = ref.watch(lyricsDataProvider(currentSong));
    final activeIndex = ref.watch(currentLyricIndexProvider(currentSong));
    
    final playerState = ref.watch(playbackStateProvider).value;
    final isPlaying = playerState?.playing ?? false;
    final positionData = ref.watch(positionDataProvider).value;
    
    // Auto-scroll logic hook
    ref.listen(currentLyricIndexProvider(currentSong), (prev, next) {
      _scrollToActive(next);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF4A5568), // Theme color from images
      body: SafeArea(
        child: Column(
          children: [
            // Drag handle at top
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronDown, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentSong.artistName ?? 'Nghệ sĩ',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lyrics List
            Expanded(
              child: lyricsAsync.when(
                data: (data) {
                  if (data.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 150),
                    itemCount: data.lines.length,
                    itemBuilder: (context, index) {
                      final line = data.lines[index];
                      final isActive = index == activeIndex;
                      
                      return GestureDetector(
                        onTap: () {
                          if (line.time != Duration.zero) {
                            ref.read(audioHandlerProvider).seek(line.time);
                          }
                        },
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: isActive ? 32 : 28,
                            fontWeight: FontWeight.w800, // Extra bold like image
                            color: isActive ? Colors.white : Colors.white24,
                            height: 1.6,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(line.text),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () {
                  // Show the empty state message immediately during the loading phase
                  // To provide the fastest result to the user.
                  return _buildEmptyState();
                },
                error: (err, _) => _buildEmptyState(message: 'Lỗi tải lời bài hát'),
              ),
            ),

            // Mini Controls Area at bottom
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF4A5568),
                    const Color(0xFF4A5568).withOpacity(0.9),
                    const Color(0xFF4A5568).withOpacity(0.0),
                  ],
                ),
              ),
              child: Column(
                children: [
                  ProgressBar(
                    position: positionData?.position ?? Duration.zero,
                    duration: positionData?.duration ?? Duration.zero,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.skipBack, color: Colors.white, size: 30),
                        onPressed: () => ref.read(audioHandlerProvider).skipToPrevious(),
                      ),
                      const SizedBox(width: 32),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: IconButton(
                          icon: Icon(isPlaying ? LucideIcons.pause : LucideIcons.play, color: Colors.black, size: 36),
                          onPressed: () => ref.read(audioHandlerProvider).togglePlayPause(),
                        ),
                      ),
                      const SizedBox(width: 32),
                      IconButton(
                        icon: const Icon(LucideIcons.skipForward, color: Colors.white, size: 30),
                        onPressed: () => ref.read(audioHandlerProvider).skipToNext(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({String message = 'Chưa có lời bài hát cho bài này'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.music, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          Text(
            message, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }
}
