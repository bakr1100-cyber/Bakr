# Splash-screen logo needs more lively motion

The user flagged this as a "demnächst" (later) item, not an immediate fix.

Where: `lib/screens/onboarding/splash_screen.dart` - the very first screen,
logo only, before the language picker.

Current state: the logo already does a fade + scale-up (0.82 -> 1.0) over
~720ms (`_logoFade`/`_logoScale` in `_SplashScreenState`), then the screen
auto-advances.

Ask: make it feel more "lebendig" (alive) - starting smaller and growing
bigger, with a clearer sense of motion than the current subtle scale. Worth
trying a more pronounced scale range and/or a bouncier curve
(`Curves.easeOutBack`/elastic) instead of the current easing, possibly with
a bit more entrance distance or a second beat (e.g. a small overshoot then
settle).
