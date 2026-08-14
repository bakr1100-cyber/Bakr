import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Plays synthesized speech in the browser via the Web Audio API, with an
/// `<audio>` element as fallback.
///
/// Web Audio is the primary path deliberately, following the evidence
/// rather than the more obvious API: on the user's iPhone the `<audio>`
/// element route produced nothing at all, while a Web Audio beep played
/// fine in the very same browser on the very same page. It also sidesteps
/// three separate `<audio>` pitfalls found along the way:
///
/// 1. `audioplayers` hands bytes to the element as a `data:` URI, which
///    iOS refuses to play.
/// 2. Its `play()` lands several `await`s after the tap, by which point the
///    gesture has expired and Safari blocks the call.
/// 3. Priming the element while muted grants no audio activation at all,
///    since iOS permits muted playback unconditionally.
///
/// An AudioContext, once resumed inside a real gesture, stays usable for
/// the rest of the session - exactly what a voice assistant needs, because
/// its audio only arrives after a network round-trip.

web.AudioContext? _context;
web.AudioBufferSourceNode? _source;
web.HTMLAudioElement? _element;
String? _elementUrl;

web.AudioContext? _ensureContext() {
  try {
    return _context ??= web.AudioContext();
  } catch (_) {
    return null;
  }
}

bool get webAudioAvailable => true;

/// Must run **synchronously** inside a user gesture, before any `await`.
///
/// Resumes the AudioContext and plays one silent sample - the long-standing
/// iOS unlock. Both halves matter: a context created outside a gesture
/// starts suspended, and Safari only lifts that on a gesture-initiated
/// resume.
void unlockWebAudio() {
  final context = _ensureContext();
  if (context == null) return;
  try {
    context.resume();
    final source = context.createBufferSource()
      ..buffer = context.createBuffer(1, 1, 22050);
    source.connect(context.destination);
    source.start();
  } catch (_) {
    // A failed unlock only means playWebAudio reports failure later, which
    // the caller handles by falling back to the device voice.
  }
}

/// Returns whether sound actually started, so a blocked play falls back to
/// the device's own voice instead of leaving the user with silence.
Future<bool> playWebAudio(Uint8List bytes, String mimeType) async {
  final context = _ensureContext();
  if (context != null) {
    try {
      if (context.state == 'suspended') await context.resume().toDart;
      // decodeAudioData may detach the buffer it is handed, so give it a
      // copy rather than the caller's bytes.
      final buffer =
          await context.decodeAudioData(Uint8List.fromList(bytes).buffer.toJS).toDart;
      stopWebAudio();
      final source = context.createBufferSource()..buffer = buffer;
      source.connect(context.destination);
      source.start();
      _source = source;
      return true;
    } catch (_) {
      // Fall through: some Safari builds refuse decodeAudioData for certain
      // MP3s even where element playback would have worked.
    }
  }
  return _playViaElement(bytes, mimeType);
}

Future<bool> _playViaElement(Uint8List bytes, String mimeType) async {
  try {
    final element = _element ??= web.HTMLAudioElement()
      ..preload = 'auto'
      ..setAttribute('playsinline', 'true');
    final previous = _elementUrl;
    if (previous != null) web.URL.revokeObjectURL(previous);
    _elementUrl = web.URL.createObjectURL(
      web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType)),
    );
    element
      ..muted = false
      ..volume = 1
      ..src = _elementUrl!;
    await element.play().toDart;
    return true;
  } catch (_) {
    return false;
  }
}

void stopWebAudio() {
  try {
    _source?.stop();
  } catch (_) {
    // Already finished.
  }
  _source = null;
  try {
    _element?.pause();
  } catch (_) {
    // Nothing playing.
  }
}
