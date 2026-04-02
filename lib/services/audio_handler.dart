import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song.dart';

class AudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  AudioPlayer get player => _player;

  // We keep a local list to help with some logic, though just_audio tracks it
  List<Song> _currentQueue = [];
  List<Song> get currentQueue => _currentQueue;

  Future<Song?> Function()? onNeedsRandomSong;

  Future<void> init({Future<Song?> Function()? onNeedsRandomSong}) async {
    this.onNeedsRandomSong = onNeedsRandomSong;
    // We don't set the audio source here to avoid "Unexpected null value" 
    // errors when the playlist is empty. The source will be set 
    // automatically in playSong() or playPlaylist().
    
    // Auto-play next random song when reaching the end if LoopMode is off
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && 
          _player.loopMode == LoopMode.off) {
        _playRandomFallback();
      }
    });
  }
  
  Future<void> _playRandomFallback() async {
    if (onNeedsRandomSong != null) {
      final randomSong = await onNeedsRandomSong!();
      if (randomSong != null) {
        await playNext(randomSong);
        await _player.seekToNext();
        await _player.play();
      }
    }
  }

  Future<void> playSong(Song song, {List<Song>? contextQueue}) async {
    _currentQueue = contextQueue ?? [song];
    final index = _currentQueue.indexWhere((s) => s.id == song.id);
    
    await _updatePlaylist(_currentQueue);
    await _player.setAudioSource(_playlist, initialIndex: index >= 0 ? index : 0);
    await _player.play();
  }
  
  Future<void> playPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    _currentQueue = List.from(songs);
    await _updatePlaylist(_currentQueue);
    await _player.setAudioSource(_playlist, initialIndex: initialIndex);
    await _player.play();
  }

  Future<void> playNext(Song song) async {
    final currentIndex = _player.currentIndex ?? 0;
    final insertIndex = currentIndex + 1;
    
    // Update local queue
    _currentQueue.insert(insertIndex, song);
    
    // Create source
    final source = AudioSource.uri(
      Uri.parse(song.audioUrl),
      tag: MediaItem(
        id: song.id.toString(),
        title: song.title,
        artist: song.artistName,
        artUri: song.coverUrl != null ? Uri.parse(song.coverUrl!) : null,
      ),
    );
    
    // Insert into just_audio playlist
    await _playlist.insert(insertIndex, source);
  }


  Future<void> _updatePlaylist(List<Song> songs) async {
    await _playlist.clear();
    final sources = songs.map((song) => AudioSource.uri(
      Uri.parse(song.audioUrl),
      tag: MediaItem(
        id: song.id.toString(),
        title: song.title,
        artist: song.artistName,
        artUri: song.coverUrl != null ? Uri.parse(song.coverUrl!) : null,
      ),
    )).toList();
    await _playlist.addAll(sources);
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_player.loopMode == LoopMode.all && currentQueue.isNotEmpty) {
      await _player.seek(Duration.zero, index: 0);
    } else if (_player.loopMode == LoopMode.off) {
      // At the end of playlist, LoopMode is off -> Fallback to a random song
      await _playRandomFallback();
    }
  }

  Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  Future<void> setShuffleModeEnabled(bool enabled) async {
    if (enabled) {
      await _player.shuffle();
    }
    await _player.setShuffleModeEnabled(enabled);
  }

  void dispose() {
    _player.dispose();
  }
}
