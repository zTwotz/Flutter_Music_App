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

  Future<void> init() async {
    // just_audio_background initialization is usually handled in main.dart
    // but we ensure the source is set
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error initializing audio source: $e");
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
    }
  }

  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
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
