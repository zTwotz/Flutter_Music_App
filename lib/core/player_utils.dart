import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';

extension PlayerNavigation on BuildContext {
  /// Plays a song or navigates to the player screen if it's already playing.
  /// 
  /// - If [song] is already the current song, navigates to `/player`.
  /// - If [song] is different, updates the playback state and plays the [queue].
  void playOrNavigate(WidgetRef ref, Song song, List<Song> queue, {int initialIndex = 0}) {
    final current = ref.read(currentSongProvider);
    if (current?.id == song.id) {
      // Already playing, navigate to player
      push('/player');
    } else {
      // Different song, just play and stay
      ref.read(currentSongProvider.notifier).setSong(song);
      ref.read(audioHandlerProvider).playPlaylist(queue, initialIndex: initialIndex);
    }
  }
}
