# Voice STT/TTS quality on Safari

Proposed but not built: migrate voice input/output from Safari's native Web
Speech API to Cloudflare Workers AI's Whisper (STT) + MeloTTS (TTS) via new
`/ai/stt` and `/ai/tts` Worker routes (same infra as the existing
`/ai/chat` route in `cloudflare-worker/src/index.js`).

Would likely fix STT accuracy issues (e.g. picking up the word "Erlauben"
from the permission dialog, garbled Darija transcripts) and reduce reliance
on manually pressing send. Not started - real effort, and Safari's
`MediaRecorder` support for raw audio capture is itself sometimes flaky, so
it isn't guaranteed to fully fix everything either.
