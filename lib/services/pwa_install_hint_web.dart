import 'dart:html' as html;

/// True if this tab is running as an installed PWA (Android "Add to Home
/// screen" / desktop "Install app") rather than a normal browser tab -
/// `display-mode: standalone` is the standard CSS media feature for this.
///
/// iOS Safari (the platform this matters most for, since it's the only
/// browser choice on an iPad) doesn't support that media query at all, so
/// this under-detects there: an already-installed iOS user may still see
/// the hint once. That's an acceptable gap - the hint is dismissible and
/// the dismissal is remembered - versus the fragility of reading iOS's
/// non-standard, JS-interop-only `navigator.standalone` property.
bool isRunningAsInstalledPwa() {
  return html.window.matchMedia('(display-mode: standalone)').matches;
}
