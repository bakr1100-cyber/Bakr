import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Plays synthesized speech in the browser through a single, long-lived
/// `<audio>` element that the app unlocks itself.
///
/// This exists because neither half of the obvious approach works on iOS
/// Safari, which is this app's main target:
///
/// 1. `audioplayers` feeds bytes to the player as a `data:` URI
///    (`setSourceBytes` -> `Uri.dataFromBytes`), and Safari refuses to play
///    audio from those.
/// 2. More fundamentally, Safari only permits playback when `play()` is
///    invoked *directly* inside a user gesture. `audioplayers` reaches its
///    `player.play()` after several `await`s (set the source, resume the
///    audio context, then play), by which point the gesture has ended and
///    the call is blocked.
///
/// Both failures are silent - the promise resolves, nothing is heard -
/// which also defeated the "fall back to the native voice" logic, since
/// from the app's side nothing had failed.
///
/// Keeping one element and unlocking it synchronously on the first tap
/// fixes both: the element stays unlocked for the rest of the session, so
/// later playback started after a network round-trip is still allowed.
/// [playWebAudio] also reports honestly whether playback actually began.

html.AudioElement? _element;
String? _currentUrl;

html.AudioElement _ensureElement() {
  return _element ??= html.AudioElement()
    ..preload = 'auto'
    // Without playsinline iOS may hand playback to the fullscreen player.
    ..setAttribute('playsinline', 'true')
    ..setAttribute('webkit-playsinline', 'true');
}

void _releaseCurrentUrl() {
  final url = _currentUrl;
  if (url == null) return;
  _currentUrl = null;
  try {
    html.Url.revokeObjectUrl(url);
  } catch (_) {
    // Already gone - nothing to release.
  }
}

String? _blobUrl(Uint8List bytes, String mimeType) {
  try {
    return html.Url.createObjectUrlFromBlob(html.Blob(<dynamic>[bytes], mimeType));
  } catch (_) {
    return null;
  }
}

bool get webAudioAvailable => true;

/// Must be called **synchronously** from inside a user gesture (a tap),
/// before any `await`. Plays a near-silent clip purely to mark the element
/// as user-activated; everything afterwards in the session may then start
/// playback on its own.
void unlockWebAudio() {
  try {
    final element = _ensureElement();
    final url = _blobUrl(_silentWav, 'audio/wav');
    if (url == null) return;
    _releaseCurrentUrl();
    _currentUrl = url;
    element
      ..muted = true
      ..src = url;
    // Deliberately not awaited: the point is that this call happens inside
    // the gesture's own call stack.
    element.play().catchError((Object _) {});
  } catch (_) {
    // An unlock that fails just means playback may be blocked later, which
    // playWebAudio reports so the caller can fall back to the native voice.
  }
}

/// Returns whether playback actually started, so a blocked or failed play
/// can fall back to the device's own voice instead of being silent.
Future<bool> playWebAudio(Uint8List bytes, String mimeType) async {
  final element = _ensureElement();
  final url = _blobUrl(bytes, mimeType);
  if (url == null) return false;

  _releaseCurrentUrl();
  _currentUrl = url;
  element
    ..muted = false
    ..volume = 1
    ..src = url;
  try {
    await element.play();
    return true;
  } catch (_) {
    // Safari rejects the promise when playback isn't permitted - exactly
    // the signal the caller needs.
    return false;
  }
}

void stopWebAudio() {
  try {
    _element?.pause();
  } catch (_) {
    // Nothing playing.
  }
}

/// The shortest valid silent WAV, used only to unlock the element.
final Uint8List _silentWav = Uint8List.fromList([
  0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x41, 0x56, 0x45, //
  0x66, 0x6d, 0x74, 0x20, 0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
  0x44, 0xac, 0x00, 0x00, 0x88, 0x58, 0x01, 0x00, 0x02, 0x00, 0x10, 0x00,
  0x64, 0x61, 0x74, 0x61, 0x00, 0x00, 0x00, 0x00,
]);
