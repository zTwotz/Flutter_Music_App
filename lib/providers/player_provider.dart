import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:async/async.dart';
import '../services/audio_handler.dart';
import '../models/song.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_provider.dart';

final audioHandlerProvider = Provider<AudioHandler>((ref) {
  final songRepo = ref.read(songRepositoryProvider);
  final handler = AudioHandler()..init(
    onNeedsRandomSong: () => songRepo.fetchRandomSong(),
  );
  ref.onDispose(() => handler.dispose());
  return handler;
});

// A stream provider for the detailed sequence state (current index and track list)
final sequenceStateProvider = StreamProvider<SequenceState?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.sequenceStateStream;
});

// The current song provider is now reactively derived from the player's state
final currentSongProvider = Provider<Song?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  final seqState = ref.watch(sequenceStateProvider).value;
  
  if (seqState == null) return null;
  
  // Get current item from the player's tag (MediaItem)
  final currentItem = seqState.currentSource?.tag as MediaItem?;
  if (currentItem == null) return null;
  
  // Find in our queue to return a full Song object with URL
  try {
    return handler.currentQueue.firstWhere(
      (s) => s.id.toString() == currentItem.id,
    );
  } catch (e) {
    // If just-in-time lookup fails, reconstruct basic info from the MediaItem
    return Song(
      id: int.parse(currentItem.id),
      title: currentItem.title,
      artistName: currentItem.artist,
      coverUrl: currentItem.artUri?.toString(),
      audioUrl: '', // Not used for UI display
    );
  }
});

final playbackStateProvider = StreamProvider<PlayerState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.playerStateStream;
});

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

final positionDataProvider = StreamProvider<PositionData>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
    handler.player.positionStream,
    handler.player.bufferedPositionStream,
    handler.player.durationStream,
    (position, bufferedPosition, duration) => PositionData(
      position,
      bufferedPosition,
      duration ?? Duration.zero,
    ),
  );
});

final loopModeProvider = StreamProvider<LoopMode>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.loopModeStream;
});

final shuffleModeEnabledProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.shuffleModeEnabledStream;
});

// ─── Supabase Sync Logic ──────────────────────────────────────────────────────

final playerSyncProvider = Provider.autoDispose<void>((ref) {
  final user = ref.watch(authStateProvider).value?.session?.user;
  if (user == null) return;

  final handler = ref.watch(audioHandlerProvider);
  final repo = ref.watch(playerRepositoryProvider);
  
  Timer? debounceTimer;

  // Listen to important changes
  ref.listen(currentSongProvider, (previous, next) {
    if (next != null) {
      try {
        repo.logListen(userId: user.id, songId: next.id.toString());
      } catch (e) {
        print('Error logging listen: $e');
      }
      try {
        _sync(ref, user.id, next, handler, repo);
      } catch (e) {
        print('Error syncing state: $e');
      }
    }
  });

  // Periodically sync position (every 10 seconds or on pause)
  final subscription = handler.player.positionStream.listen((pos) {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(seconds: 10), () {
      final song = ref.read(currentSongProvider);
      if (song != null) {
        try {
          _sync(ref, user.id, song, handler, repo);
        } catch (e) {
          print('Error periodic syncing state: $e');
        }
      }
    });
  });

  ref.onDispose(() {
    subscription.cancel();
    debounceTimer?.cancel();
  });
});

void _sync(Ref ref, String userId, Song song, AudioHandler handler, dynamic repo) {
  try {
    repo.updatePlayerState(
      userId: userId,
      currentSongId: song.id.toString(),
      currentPlaylistId: null, // Track playlist ID if needed
      positionSeconds: handler.player.position.inSeconds,
      repeatMode: handler.player.loopMode.name,
      shuffleEnabled: handler.player.shuffleModeEnabled,
    );
  } catch (e) {
    print('Sync failed: $e');
  }
}

// Rx helper for combineLatest
class Rx {
  static Stream<T> combineLatest3<A, B, C, T>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    T Function(A a, B b, C c) combiner,
  ) async* {
    A? lastA;
    B? lastB;
    C? lastC;
    
    await for (final value in StreamGroup.merge([
      streamA.map((v) => _Event(0, v)),
      streamB.map((v) => _Event(1, v)),
      streamC.map((v) => _Event(2, v)),
    ])) {
      if (value.index == 0) lastA = value.data as A;
      if (value.index == 1) lastB = value.data as B;
      if (value.index == 2) lastC = value.data as C;
      
      if (lastA != null && lastB != null && lastC != null) {
        yield combiner(lastA, lastB, lastC);
      }
    }
  }
}

class _Event {
  final int index;
  final dynamic data;
  _Event(this.index, this.data);
}
