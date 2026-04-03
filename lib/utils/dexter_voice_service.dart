import 'package:audioplayers/audioplayers.dart'
    show AssetSource, AudioPlayer, ReleaseMode;

class DexterVoiceService {
  DexterVoiceService._();

  static final DexterVoiceService instance = DexterVoiceService._();
  static const Map<String, String> _voiceAssets = {
    'I am Dexter, the engine on the red side. Many call me unbeatable. You may test that rumor yourself.':
        'sounds/dexter/intro_1.wav',
    'Dexter online. I do not rely on luck. I reduce this board to numbers.':
        'sounds/dexter/intro_2.wav',
    'You are facing Dexter now. I have already started counting your mistakes.':
        'sounds/dexter/intro_3.wav',
    'Your turn. Try to make it matter.': 'sounds/dexter/move_1.wav',
    'I prefer precise moves. That was one.': 'sounds/dexter/move_2.wav',
    'The board is narrowing. You should feel that.':
        'sounds/dexter/move_3.wav',
    'I have made my choice. Now make yours.':
        'sounds/dexter/move_4.wav',
    'That piece was already mine.': 'sounds/dexter/capture_1.wav',
    'You left me the cleanest capture.': 'sounds/dexter/capture_2.wav',
    'I saw that exchange long before you did.':
        'sounds/dexter/capture_3.wav',
    'A Dama for me. This board just tilted further my way.':
        'sounds/dexter/promotion_1.wav',
    'Promotion complete. That should complicate your plans.':
        'sounds/dexter/promotion_2.wav',
    'You let Dexter grow stronger. Bold decision.':
        'sounds/dexter/promotion_3.wav',
    'Still thinking? Sensible.': 'sounds/dexter/slow_1.wav',
    'I finished calculating your position a while ago.':
        'sounds/dexter/slow_2.wav',
    'Take your time. Pressure reveals everything eventually.':
        'sounds/dexter/slow_3.wav',
    'The clock is doing more work than your pieces.':
        'sounds/dexter/pressure_1.wav',
    'Time is almost out. My evaluation is not.':
        'sounds/dexter/pressure_2.wav',
    'Interesting. You need the full clock for this one.':
        'sounds/dexter/pressure_3.wav',
    'The clock moved for you. Merciless.': 'sounds/dexter/timeout_1.wav',
    'Time made your move. I will accept the charity.':
        'sounds/dexter/timeout_2.wav',
    'Even the timer refused to wait for you.':
        'sounds/dexter/timeout_3.wav',
    'Expected. I told you I calculate endings.':
        'sounds/dexter/win_1.wav',
    'Dexter wins. The board behaved exactly as predicted.':
        'sounds/dexter/win_2.wav',
    'Another proof that calculation beats hope.':
        'sounds/dexter/win_3.wav',
    'Well played. That result will bother me for quite some time.':
        'sounds/dexter/loss_1.wav',
    'You found the answer. Enjoy it.': 'sounds/dexter/loss_2.wav',
    'Impressive. I will remember this one.': 'sounds/dexter/loss_3.wav',
    'A draw. Acceptable, though not ideal.': 'sounds/dexter/draw_1.wav',
    'You escaped with equality. For now.': 'sounds/dexter/draw_2.wav',
  };

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }

    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(1.0);
    _initialized = true;
  }

  Future<void> speak(
    String text, {
    double pitch = 0.88,
    double rate = 0.46,
  }) async {
    final message = text.trim();
    if (message.isEmpty) {
      return;
    }

    final asset = _voiceAssets[message];
    if (asset == null) {
      return;
    }

    try {
      await _ensureInitialized();
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      // Fail quietly so gameplay is not interrupted if audio playback fails.
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // Fail quietly so gameplay is not interrupted if audio playback fails.
    }
  }
}
