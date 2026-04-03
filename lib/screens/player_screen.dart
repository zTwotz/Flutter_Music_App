import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/player_provider.dart';
import '../providers/favorite_provider.dart';
import '../core/app_theme.dart';
import '../widgets/add_to_playlist_bottom_sheet.dart';
import '../widgets/player_options_bottom_sheet.dart';
import '../widgets/progress_bar.dart';
import '../widgets/lyrics_preview_card.dart';
import '../widgets/download_status_widgets.dart';
import '../providers/download_provider.dart';
import '../services/artist_service.dart';

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
    final processingState = playerState?.processingState ?? ProcessingState.idle;
    final isLoading = processingState == ProcessingState.loading || processingState == ProcessingState.buffering;
    final duration = positionData?.duration ?? Duration.zero;
    final position = positionData?.position ?? Duration.zero;

    final isLikedAsync = ref.watch(isLikedProvider(currentSong.id));
    final isLiked = isLikedAsync.value ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Cover Blur
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: _buildCoverImage(currentSong.coverUrl, isFull: true),
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

          // Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
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
                        Column(
                          children: [
                            const Text(
                              'ĐANG PHÁT TỪ',
                              style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white54, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (ref.watch(downloadProvider.notifier).isDownloaded(currentSong.id)) 
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: OfflineBadge(),
                                  ),
                                const Text(
                                  'Âm nhạc cho bạn',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),


                        IconButton(
                          icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
                          onPressed: () => showPlayerOptionsBottomSheet(context, ref, currentSong),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cover Image
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Hero(
                      tag: 'player-cover',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _buildCoverImage(currentSong.coverUrl, isFull: true),
                          ),
                        ),

                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title & Metadata
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
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              ClickableArtistText(
                                text: currentSong.artistName ?? 'Nghệ sĩ',
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isLiked ? LucideIcons.heart : LucideIcons.heart,
                            fill: isLiked ? 1.0 : 0.0,
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

                  const SizedBox(height: 32),

                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ProgressBar(position: position, duration: duration),
                  ),

                  const SizedBox(height: 24),

                  // Controls
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
                          child: isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                                )
                              : IconButton(
                                  icon: Icon(isPlaying ? LucideIcons.pause : LucideIcons.play, size: 40, color: Colors.black),
                                  onPressed: () => ref.read(audioHandlerProvider).togglePlayPause(),
                                ),
                        ),
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
                  ),

                  const SizedBox(height: 40),

                  // Lyrics Preview
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LyricsPreviewCard(song: currentSong),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(String? url, {bool isFull = false}) {
    if (url == null) {
      return Container(
        color: AppTheme.surfaceHighlight,
        child: Icon(LucideIcons.music, size: isFull ? 80 : 20, color: Colors.white24),
      );
    }
    
    if (url.startsWith('/') || url.startsWith('file://')) {
      final path = url.replaceFirst('file://', '');
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceHighlight),
      );
    }
    
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceHighlight),
    );
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
      final artist = await ArtistService.findArtistByName(artistName);

      if (!mounted) return;

      if (artist != null) {
        context.pop();
        context.push('/artist/${artist.id}', extra: artist);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy thông tin nghệ sĩ "${artistName.trim()}"')),
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
      final precedingText = widget.text.substring(lastMatchEnd, match.start);
      if (precedingText.isNotEmpty) {
        final recognizer = TapGestureRecognizer()..onTap = () => _handleArtistTap(precedingText);
        _recognizers.add(recognizer);
        spans.add(TextSpan(text: precedingText, style: linkStyle, recognizer: recognizer));
      }
      final delimiter = match.group(0)!;
      spans.add(TextSpan(text: delimiter, style: normalStyle));
      lastMatchEnd = match.end;
    }

    final remainingText = widget.text.substring(lastMatchEnd);
    if (remainingText.isNotEmpty) {
      final recognizer = TapGestureRecognizer()..onTap = () => _handleArtistTap(remainingText);
      _recognizers.add(recognizer);
      spans.add(TextSpan(text: remainingText, style: linkStyle, recognizer: recognizer));
    }

    return SizedBox(
      width: double.infinity,
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(children: spans),
      ),
    );
  }
}


