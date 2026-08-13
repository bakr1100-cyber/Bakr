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

### MeloTTS does not work at all right now - cloud voice is DISABLED
Corrected finding. An earlier read of this was too optimistic ("transient
capacity, request shape is fine"). Probing each language separately across
four deploys shows it has **never once returned audio**, with three
different errors:

| attempt | lang | error |
|---|---|---|
| 1-3 | fr | `3040: Capacity temporarily exceeded` |
| 4 | en | `3043: Internal server error` |
| 4 | fr | `8002: Invalid input` |

`8002` on a plain `fr` request is a known, undocumented per-language gap in
Cloudflare's MeloTTS wrapper (cloudflare/cloudflare-docs#23308) - not
something fixable from this repo.

**So the cloud voice is now off by default** (`_cloudTtsEnabledByDefault`
in `voice_service.dart`). Leaving it on was not harmless: every
French/English reply would first spend a network round-trip failing before
the native voice started speaking, i.e. the user waits longer to hear the
exact same voice as before. With it off, French/English behave precisely as
they did before this feature existed.

The whole path stays wired up and tested behind that one flag. The deploy
smoke test now probes `en` and `fr` separately on every deploy and prints
`lang=xx OK` when it works - **flip the flag back to `true` when that
appears**, nothing else needs changing.

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
