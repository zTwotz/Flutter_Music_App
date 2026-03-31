import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:async/async.dart';
import '../services/audio_handler.dart';
import '../models/song.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_provider.dart';

final audioHandlerProvider = Provider<AudioHandler>((ref) {
  final handler = AudioHandler()..init();
  ref.onDispose(() => handler.dispose());
  return handler;
});

class CurrentSongNotifier extends Notifier<Song?> {
  @override
  Song? build() => null;
  void setSong(Song? song) => state = song;
}

final currentSongProvider = NotifierProvider<CurrentSongNotifier, Song?>(CurrentSongNotifier.new);

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
      repo.logListen(userId: user.id, songId: next.id.toString());
      _sync(ref, user.id, next, handler, repo);
    }
  });

  // Periodically sync position (every 10 seconds or on pause)
  final subscription = handler.player.positionStream.listen((pos) {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(seconds: 10), () {
      final song = ref.read(currentSongProvider);
      if (song != null) {
        _sync(ref, user.id, song, handler, repo);
      }
    });
  });

  ref.onDispose(() {
    subscription.cancel();
    debounceTimer?.cancel();
  });
});

void _sync(Ref ref, String userId, Song song, AudioHandler handler, dynamic repo) {
  repo.updatePlayerState(
    userId: userId,
    currentSongId: song.id.toString(),
    currentPlaylistId: null, // Track playlist ID if needed
    positionSeconds: handler.player.position.inSeconds,
    repeatMode: handler.player.loopMode.name,
    shuffleEnabled: handler.player.shuffleModeEnabled,
  );
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
