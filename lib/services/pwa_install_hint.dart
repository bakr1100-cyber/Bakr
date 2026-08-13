// Conditional import: the real (dart:html-based) check only compiles for
// web; every other target (notably `flutter test`, which runs on the Dart
// VM) links the stub instead. See the two implementation files for why
// this can't just be a runtime `kIsWeb` check.
export 'pwa_install_hint_stub.dart' if (dart.library.html) 'pwa_install_hint_web.dart';
