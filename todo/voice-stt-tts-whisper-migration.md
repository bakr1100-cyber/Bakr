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

### Resolved: the cloud voice now runs on Azure Speech
Workers AI's MeloTTS never once returned audio across four deploys (three
different errors, including a known undocumented per-language gap). It is
now only the last-resort provider. The Worker instead picks a real TTS
service by configured secret (`cloudflare-worker/src/tts_providers.js`),
and **Azure Speech is live** - confirmed end to end by the deploy smoke
test for all four languages:

```
lang=de OK via 'azure'   lang=fr OK via 'azure'
lang=ar OK via 'azure'   lang=en OK via 'azure'
```

Arabic uses `ar-MA-MounaNeural` / `ar-MA-JamalNeural` - genuine Moroccan
voices, which no other candidate provider offers.

Two bugs were found and fixed getting there, both of which the per-language
smoke test caught and neither of which unit tests could have:
1. The SSML was missing `xmlns='http://www.w3.org/2001/10/synthesis'`.
   Azure rejects that with a bare HTTP 400 and an empty body.
2. `Content-Type` lacked `charset=utf-8`, so Azure decoded the body as
   single-byte text. ASCII languages were unaffected; **only** Arabic
   broke, arriving as mojibake. Worth remembering: an integration passing
   for European languages says nothing about whether it handles Arabic.

## Speech-to-text (input): Whisper added as a fallback, native path untouched
The primary voice-input experience is deliberately unchanged: native Web
Speech API (`speech_to_text` package) is still used whenever it's
available, with its live partial transcripts as you speak - the exact,
already-working, already-tested behavior on your iPad Safari. Rewriting
that path wasn't worth the risk: Whisper via Workers AI isn't streaming,
so replacing native STT outright would have meant losing live captions or
a fundamentally different recording-then-transcribe UX, on the one part of
the app with the most history of confusing/broken-seeming behavior - and
this environment can't play back real audio to verify a change like that
before shipping it.

Instead, `VoiceService.startListening()` now falls back to recording +
`/ai/stt` (Whisper) transcription **only when the native engine isn't
available at all** (e.g. a browser with no Web Speech API support at all -
your iPad Safari has it, so it never reaches this path). Previously that
case was a dead mic button that did nothing when tapped, silently; now it
records audio (`record` package, AAC/M4A - the format Safari's own
MediaRecorder uses, and one of Whisper's documented supported input
formats), uploads it once you stop, and fills in the transcribed text -
just without live partial captions while recording, since Whisper can't
provide those.

Covered by `test/voice_service_test.dart` (availability + routing logic,
and that a failed recording attempt degrades gracefully rather than
crashing - same as every other optional integration in this app). Actual
end-to-end recording/transcription on a real browser without Web Speech
API support hasn't been (and can't be, from this environment) verified
live - if you ever see something odd with voice input on a *different*
device/browser than your usual iPad, that's the path to check first.
