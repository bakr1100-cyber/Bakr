import 'dart:html' as html;
import 'dart:typed_data';

/// Wraps [bytes] in a blob and returns an object URL for it.
///
/// This exists specifically to work around iOS Safari. `audioplayers`'
/// web implementation turns a `BytesSource` into a `data:` URI
/// (`setSourceBytes` -> `Uri.dataFromBytes`), and Safari on iOS refuses to
/// play audio from a `data:` URI - without raising an error. The call
/// resolves, the player reports success, and nothing is ever heard, which
/// also defeats any "fall back to the native voice on failure" logic,
/// because from the app's side nothing failed.
///
/// A blob URL is the standard workaround and plays reliably there.
/// Returns null if the browser refuses to create one, so callers can fall
/// back to the bytes path rather than losing audio entirely.
String? createAudioBlobUrl(Uint8List bytes, String mimeType) {
  try {
    return html.Url.createObjectUrlFromBlob(html.Blob(<dynamic>[bytes], mimeType));
  } catch (_) {
    return null;
  }
}

/// Blob URLs pin their data in memory until revoked, so every URL from
/// [createAudioBlobUrl] must be released once playback no longer needs it.
void revokeAudioBlobUrl(String url) {
  try {
    html.Url.revokeObjectUrl(url);
  } catch (_) {
    // Already revoked, or the document went away - nothing to clean up.
  }
}
