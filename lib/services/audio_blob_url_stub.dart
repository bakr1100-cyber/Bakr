import 'dart:typed_data';

/// Non-web targets use the `audioplayers` path instead - see
/// [VoiceService._play].
bool get webAudioAvailable => false;

void unlockWebAudio() {}

Future<bool> playWebAudio(Uint8List bytes, String mimeType) async => false;

void stopWebAudio() {}
