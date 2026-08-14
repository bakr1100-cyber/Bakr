// Conditional import: the real (dart:html-based) implementation only
// compiles for web; every other target (notably `flutter test`, which runs
// on the Dart VM) links the stub instead.
export 'audio_blob_url_stub.dart' if (dart.library.html) 'audio_blob_url_web.dart';
