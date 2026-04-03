import 'package:audioplayers/audioplayers.dart' show AudioPlayer, ReleaseMode, AssetSource;

/// Sound effect types available in the game.
enum GameSound {
  click,
  captured,
  dma,
  gameover,
  timeout,
  music,
  timer,
  move,
}

/// Service class for playing game sound effects.
/// Provides a centralized way to manage and play sounds throughout the app.
class SoundService {
  // Singleton instance
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // Audio player for playing sounds
  AudioPlayer? _player;

  // Sound file paths - relative to assets/sounds/ folder
  static const Map<GameSound, String> _soundPaths = {
    GameSound.click: 'sounds/click.mp3',
    GameSound.captured: 'sounds/captured.mp3',
    GameSound.dma: 'sounds/dama.mp3',
    GameSound.gameover: 'sounds/gameover.mp3',
    GameSound.timeout: 'sounds/timeout.mp3',
    GameSound.music: 'sounds/music.mp3',
    GameSound.timer: 'sounds/timer.mp3',
    GameSound.move: 'sounds/move.mp3',
  };

  // Separate audio player for background music (to allow looping)
  AudioPlayer? _musicPlayer;
  bool _isMusicPlaying = false;

  /// Initialize the audio player
  Future<void> initialize() async {
    _player = AudioPlayer();
    // Use release mode that allows multiple sound effects to play
    await _player!.setReleaseMode(ReleaseMode.release);
    
    // Initialize music player with separate audio context
    _musicPlayer = AudioPlayer();
    await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
  }

  /// Play a sound effect
  Future<void> play(GameSound sound) async {
    _player ??= AudioPlayer();
    
    try {
      final filename = _soundPaths[sound]!;
      // Use play() directly for proper playback
      await _player!.play(AssetSource(filename));
    } catch (e) {
      // Log error but don't crash
      print('Sound playback error for $sound: $e');
    }
  }

  /// Play click sound (for button taps)
  Future<void> playClick() async {
    await play(GameSound.click);
  }

  /// Play captured sound (when capturing opponent chip)
  Future<void> playCaptured() async {
    await play(GameSound.captured);
  }

  /// Play Dama promotion sound
  Future<void> playDama() async {
    await play(GameSound.dma);
  }

  /// Play game over sound
  Future<void> playGameOver() async {
    await play(GameSound.gameover);
  }

  /// Play timeout sound (when turn timer expires)
  Future<void> playTimeout() async {
    await play(GameSound.timeout);
  }

  /// Play timer warning sound (when timer is <= 10 seconds)
  Future<void> playTimerWarning() async {
    await play(GameSound.timer);
  }

  /// Play move sound (when chip moves without capturing)
  Future<void> playMove() async {
    await play(GameSound.move);
  }

  /// Start background music (loops continuously)
  Future<void> startBackgroundMusic() async {
    if (_isMusicPlaying) return; // Already playing
    
    if (_musicPlayer == null) {
      _musicPlayer = AudioPlayer();
      await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
    }
    
    try {
      // Set volume BEFORE playing to ensure it's applied
      await _musicPlayer!.setVolume(0.4);
      await _musicPlayer!.play(AssetSource('sounds/music.mp3'));
      _isMusicPlaying = true;
    } catch (e) {
      print('Background music playback error: $e');
    }
  }

  /// Stop background music
  Future<void> stopBackgroundMusic() async {
    if (!_isMusicPlaying) return;
    
    try {
      await _musicPlayer?.stop();
      _isMusicPlaying = false;
    } catch (e) {
      print('Error stopping background music: $e');
    }
  }

  /// Pause background music
  Future<void> pauseBackgroundMusic() async {
    if (!_isMusicPlaying) return;
    
    try {
      await _musicPlayer?.pause();
    } catch (e) {
      print('Error pausing background music: $e');
    }
  }

  /// Resume background music
  Future<void> resumeBackgroundMusic() async {
    if (_isMusicPlaying) return;
    
    try {
      await _musicPlayer?.resume();
      _isMusicPlaying = true;
    } catch (e) {
      print('Error resuming background music: $e');
    }
  }

  /// Check if background music is playing
  bool get isMusicPlaying => _isMusicPlaying;

  /// Dispose the audio player
  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    await _musicPlayer?.dispose();
    _musicPlayer = null;
    _isMusicPlaying = false;
  }
}
