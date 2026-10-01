import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class AudioCues {
  static Future<void> lamp() => _play('lamp.wav', 0.52);
  static Future<void> hit() => _play('hit.wav', 0.48);

  static Future<void> _play(String name, double volume) async {
    try {
      await FlameAudio.play(name, volume: volume);
    } catch (error) {
      debugPrint('Could not play $name: $error');
    }
  }
}
