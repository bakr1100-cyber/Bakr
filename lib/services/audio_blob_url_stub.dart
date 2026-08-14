import 'dart:typed_data';

/// Non-web targets have no blob URLs; callers fall back to handing the
/// bytes to the audio player directly.
String? createAudioBlobUrl(Uint8List bytes, String mimeType) => null;

void revokeAudioBlobUrl(String url) {}
