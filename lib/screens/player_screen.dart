import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/player_provider.dart';
import '../providers/favorite_provider.dart';
import '../models/artist.dart';
import '../core/app_theme.dart';
import '../widgets/add_to_playlist_bottom_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final playerState = ref.watch(playbackStateProvider).value;
    final positionData = ref.watch(positionDataProvider).value;
    final loopMode = ref.watch(loopModeProvider).value ?? LoopMode.off;
    final shuffleEnabled = ref.watch(shuffleModeEnabledProvider).value ?? false;

    if (currentSong == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: Text('Không có nội dung phát')),
      );
    }

    final isPlaying = playerState?.playing ?? false;
    final duration = positionData?.duration ?? Duration.zero;
    final position = positionData?.position ?? Duration.zero;

    final isLikedAsync = ref.watch(isLikedProvider(currentSong.id));
    final isLiked = isLikedAsync.value ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Background Gradient/Blur ──
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: currentSong.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: currentSong.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox(),
                    )
                  : Container(color: AppTheme.surfaceHighlight),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.8),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Main Content ──
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.chevronDown, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Column(
                        children: [
                          Text(
                            'ĐANG PHÁT TỪ',
                            style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Âm nhạc cho bạn',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Cover Image
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Hero(
                    tag: 'player-cover',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: currentSong.coverUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: currentSong.coverUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: AppTheme.surfaceHighlight,
                                  child: const Icon(LucideIcons.music, size: 80, color: Colors.white24),
                                ),
                        ),
                      ),
                    ),
                  ),
                ).animate(
                  target: isPlaying ? 1 : 0,
                  onPlay: (controller) => controller.repeat(reverse: true),
                ).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.02, 1.02),
                  duration: 3.seconds,
                  curve: Curves.easeInOut,
                ).fadeIn(duration: 600.ms),

                const Spacer(),

                // Metadata & Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSong.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                            const SizedBox(height: 4),
                            ClickableArtistText(
                              text: currentSong.artistName ?? 'Nghệ sĩ',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isLiked ? LucideIcons.heart : LucideIcons.heart,
                          fill: isLiked ? 1 : 0,
                          color: isLiked ? AppTheme.primary : Colors.white,
                          size: 28,
                        ),
                        onPressed: () => ref.read(favoriteNotifierProvider.notifier).toggleLike(context, currentSong.id, isLiked),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.listPlus, color: Colors.white, size: 24),
                        onPressed: () => showAddToPlaylist(context, ref, currentSong),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Progress Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0), // No thumb for premium look
                          activeTrackColor: AppTheme.primary,
                          inactiveTrackColor: Colors.white.withOpacity(0.1),
                        ),
                        child: Slider(
                          min: 0,
                          max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                          value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0),
                          onChanged: (val) {
                            ref.read(audioHandlerProvider).seek(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(_formatDuration(duration), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 16),

                // Main Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          LucideIcons.shuffle,
                          color: shuffleEnabled ? AppTheme.primary : Colors.white,
                          size: 20,
                        ),
                        onPressed: () => ref.read(audioHandlerProvider).setShuffleModeEnabled(!shuffleEnabled),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.skipBack, size: 36, color: Colors.white),
                        onPressed: () => ref.read(audioHandlerProvider).skipToPrevious(),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: IconButton(
                          icon: Icon(isPlaying ? LucideIcons.pause : LucideIcons.play, size: 40, color: Colors.black),
                          onPressed: () => ref.read(audioHandlerProvider).togglePlayPause(),
                        ),
                      ).animate(target: isPlaying ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                      IconButton(
                        icon: const Icon(LucideIcons.skipForward, size: 36, color: Colors.white),
                        onPressed: () => ref.read(audioHandlerProvider).skipToNext(),
                      ),
                      IconButton(
                        icon: Icon(
                          loopMode == LoopMode.off ? LucideIcons.repeat : (loopMode == LoopMode.one ? LucideIcons.repeat1 : LucideIcons.repeat),
                          color: loopMode != LoopMode.off ? AppTheme.primary : Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          final nextMode = loopMode == LoopMode.off ? LoopMode.all : (loopMode == LoopMode.all ? LoopMode.one : LoopMode.off);
                          ref.read(audioHandlerProvider).setLoopMode(nextMode);
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),

                // Bottom Tab (Lyrics Placeholder)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.mic2, size: 18, color: Colors.white70),
                          SizedBox(width: 8),
                          Text('Lời bài hát (Sắp ra mắt)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class ClickableArtistText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const ClickableArtistText({super.key, required this.text, this.style});

  @override
  State<ClickableArtistText> createState() => _ClickableArtistTextState();
}

class _ClickableArtistTextState extends State<ClickableArtistText> {
  final List<TapGestureRecognizer> _recognizers = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (var r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _handleArtistTap(String artistName) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final name = artistName.trim();
      // Fetch artist by name using ILIKE for case-insensitive matching
      final response = await Supabase.instance.client
          .from('artists')
          .select()
          .ilike('name', name)
          .maybeSingle();

      if (!mounted) return;

      if (response != null) {
        final artistId = response['id'].toString();
        // Construct minimum artist to pass (ArtistDetailScreen fetches the rest via artistDetailProvider)
        final dummyArtist = Artist(
          id: artistId,
          name: response['name'] ?? name,
          avatarUrl: response['avatar_url'],
          coverUrl: response['cover_url'],
        );
        
        // Close the full-screen player first
        context.pop();
        
        // Push the artist screen in the main shell
        context.push('/artist/$artistId', extra: dummyArtist);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy thông tin nghệ sĩ "$name"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xảy ra lỗi khi tải hồ sơ nghệ sĩ')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    // Regex to split by delimiters: " ft ", " x ", ",", ".".
    // We capture the delimiters so we can render them as non-clickable string.
    final RegExp regex = RegExp(r'(\s+ft\s+|\s+x\s+|,|\.)', caseSensitive: false);
    final Iterable<Match> matches = regex.allMatches(widget.text);

    int lastMatchEnd = 0;
    final List<InlineSpan> spans = [];

    final TextStyle linkStyle = (widget.style ?? const TextStyle()).copyWith(
      decoration: TextDecoration.underline,
      decorationColor: Colors.white24,
    );
    final TextStyle normalStyle = widget.style ?? const TextStyle();

    for (final Match match in matches) {
      // Artist name before the delimiter
      final precedingText = widget.text.substring(lastMatchEnd, match.start);
      if (precedingText.isNotEmpty) {
        final recognizer = TapGestureRecognizer()..onTap = () => _handleArtistTap(precedingText);
        _recognizers.add(recognizer);
        spans.add(TextSpan(text: precedingText, style: linkStyle, recognizer: recognizer));
      }

      // The delimiter itself (non-clickable)
      final delimiter = match.group(0)!;
      spans.add(TextSpan(text: delimiter, style: normalStyle));

      lastMatchEnd = match.end;
    }

    // Capture the final piece (or the whole string if no matches)
    final remainingText = widget.text.substring(lastMatchEnd);
    if (remainingText.isNotEmpty) {
      final recognizer = TapGestureRecognizer()..onTap = () => _handleArtistTap(remainingText);
      _recognizers.add(recognizer);
      spans.add(TextSpan(text: remainingText, style: linkStyle, recognizer: recognizer));
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }
}
