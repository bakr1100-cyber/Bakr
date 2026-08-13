# Voice STT/TTS quality on Safari

## Done
- `cloudflare-worker/src/index.js`: added `/ai/stt` (Whisper) and `/ai/tts`
  (MeloTTS) routes, same no-signup Workers AI `[ai]` binding as `/ai/chat`.
- `lib/services/voice_service.dart`: `speak()` now tries the cloud voice
  (MeloTTS) first for French/English (the only languages it documents
  support for - German/Arabic/Darija would likely come out badly
  mispronounced, so those still go straight to the native engine), falling
  back to the native `flutter_tts` engine on any failure. Covered by
  `test/voice_service_test.dart` (the HTTP routing logic - not actual
  audio output, which needs a real device/browser to verify).

## Still open: speech-to-text (input) migration
Deliberately NOT done this pass - kept on native Web Speech API
(`speech_to_text` package) for now. Not a smaller task than TTS, for a
specific reason: native STT streams live partial transcripts as the user
speaks (`onResult(text, isFinal: false)` fires repeatedly); Whisper via
Workers AI is not streaming - it only returns a transcript after a
recording is fully uploaded. Swapping the input side means either losing
live partial captions in the chat input field, or a genuinely different
recording-then-transcribe UX, and this is the one part of the app with
the most user-reported history of confusing/broken-seeming behavior
(mic button state, locale mismatches) - risking a regression there without
being able to test live audio from this environment felt like the wrong
trade for this pass.

If picked up later: `POST /ai/stt` already exists and works the same way
`/ai/tts` does (send raw audio bytes, get `{text}` back) - the remaining
work is entirely client-side: record audio (e.g. the `record` package,
which has web support via MediaRecorder - the same API the old
`todo` note flagged as "sometimes flaky" in Safari) instead of streaming
to the native recognizer, call `/ai/stt` once recording stops, and decide
on a UX for the no-live-partial-text gap (e.g. a waveform/recording
indicator in place of live captions, only populating the text field once
transcription returns).
