/// Non-web fallback (also what `flutter test` links against, since tests
/// run on the Dart VM, not in a browser) - there's no "installed to Home
/// Screen" concept off the web, so this is trivially false everywhere it's
/// actually reachable.
bool isRunningAsInstalledPwa() => false;
