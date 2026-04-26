/// Sound placeholder — prints to console.
/// Replace with audioplayers or just_audio in production.
class SoundUtil {
  static void playCorrect()  => debugPrint('🔊 SOUND: correct_ding.mp3');
  static void playWrong()    => debugPrint('🔊 SOUND: wrong_buzz.mp3');
  static void playComplete() => debugPrint('🔊 SOUND: level_complete.mp3');
  static void playTap()      => debugPrint('🔊 SOUND: tap_pop.mp3');
  static void playCheer()    => debugPrint('🔊 SOUND: cheer.mp3');

  static void speakInstruction(String text) {
    // In production: use flutter_tts
    debugPrint('🗣️ VOICE: "$text"');
  }
}

// ignore: avoid_print
void debugPrint(String msg) => print(msg);
