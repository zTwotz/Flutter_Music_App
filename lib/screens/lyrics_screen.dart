import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dio/dio.dart';

import '../core/app_theme.dart';
import '../providers/player_provider.dart';

class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}

class LyricsScreen extends ConsumerStatefulWidget {
  const LyricsScreen({super.key});

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  
  List<LyricLine>? _lrcLines;
  String? _plainTextLyrics;
  
  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }
  
  Future<void> _fetchLyrics() async {
    final currentSong = ref.read(currentSongProvider);
    if (currentSong == null) {
      setState(() {
        _isError = true;
        _errorMessage = 'Không có bài hát nào';
        _isLoading = false;
      });
      return;
    }
    
    // If we have plain text lyrics locally already
    if (currentSong.lyrics != null && currentSong.lyrics!.isNotEmpty) {
      _processLyrics(currentSong.lyrics!);
      return;
    }
    
    // If we have a URL, fetch it
    if (currentSong.lyricsUrl != null && currentSong.lyricsUrl!.isNotEmpty) {
      try {
        final response = await Dio().get(currentSong.lyricsUrl!);
        final content = response.data.toString();
        _processLyrics(content);
      } catch (e) {
        setState(() {
          _isError = true;
          _errorMessage = 'Không thể tải lời bài hát';
          _isLoading = false;
        });
      }
      return;
    }
    
    // Neither available
    setState(() {
      _isError = true;
      _errorMessage = 'Bài hát này chưa có lời';
      _isLoading = false;
    });
  }
  
  void _processLyrics(String rawContent) {
    if (rawContent.contains(RegExp(r'\[\d{2}:\d{2}\.\d{2}\]'))) {
      // It's LRC format
      _lrcLines = _parseLrc(rawContent);
    } else {
      // Plain text
      _plainTextLyrics = rawContent;
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  List<LyricLine> _parseLrc(String lrc) {
    final List<LyricLine> lines = [];
    final regExp = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    
    for (final line in lrc.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final int min = int.parse(match.group(1)!);
        final int sec = int.parse(match.group(2)!);
        final int ms = int.parse(match.group(3)!);
        final String text = match.group(4)!.trim();
        
        if (text.isNotEmpty) {
          final Duration time = Duration(minutes: min, seconds: sec, milliseconds: ms.toString().length == 2 ? ms * 10 : ms);
          lines.add(LyricLine(time: time, text: text));
        }
      }
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider);
    final positionData = ref.watch(positionDataProvider).value;
    final position = positionData?.position ?? Duration.zero;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronDown, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              currentSong?.title ?? 'Lời bài hát',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (currentSong?.artistName != null)
              Text(
                currentSong!.artistName!,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: _buildBody(position),
    );
  }

  Widget _buildBody(Duration position) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    
    if (_isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.listMusic, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    if (_plainTextLyrics != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Text(
          _plainTextLyrics!,
          style: const TextStyle(
            fontSize: 24,
            height: 1.6,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
          textAlign: TextAlign.left,
        ),
      );
    }
    
    if (_lrcLines != null && _lrcLines!.isNotEmpty) {
      return ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: MediaQuery.of(context).size.height * 0.3),
        itemCount: _lrcLines!.length,
        itemBuilder: (context, index) {
          final line = _lrcLines![index];
          final isNextLinePassed = index + 1 < _lrcLines!.length ? position >= _lrcLines![index + 1].time : false;
          final isActive = position >= line.time && !isNextLinePassed;
          
          if (isActive) {
            // Very simple auto-scroll mechanism
            WidgetsBinding.instance.addPostFrameCallback((_) {
               if (_scrollController.hasClients) {
                 final targetOffset = (index * 56.0) - (MediaQuery.of(context).size.height * 0.15);
                 _scrollController.animateTo(
                   targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
                   duration: const Duration(milliseconds: 300),
                   curve: Curves.easeInOut,
                 );
               }
            });
          }

          return Container(
            height: 56, // Fixed rough height for scroll calculation
            alignment: Alignment.centerLeft,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isActive ? 32 : 24,
                height: 1.4,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? Colors.white : Colors.white24,
              ),
              child: Text(line.text),
            ),
          );
        },
      );
    }
    
    return const SizedBox();
  }
}
