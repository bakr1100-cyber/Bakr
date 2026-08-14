/**
 * Text-to-speech providers, tried in order of preference.
 *
 * The app is being walked through several TTS services one at a time to
 * compare how they actually sound (Workers AI's own MeloTTS has never once
 * returned audio - see todo/voice-stt-tts-whisper-migration.md). So rather
 * than hard-wiring one vendor, every provider here speaks the same tiny
 * contract - `(text, lang) -> {audioBase64, mimeType}` - and is selected
 * purely by which secrets happen to be configured on the Worker.
 *
 * That means switching or adding a provider is a Cloudflare secret change
 * and nothing else: no code edit, no redeploy of the Flutter app, and the
 * client never learns which one answered.
 *
 * Order is deliberate: Azure first because it is the only one of these with
 * genuine Moroccan Arabic (ar-MA) voices, which for this app's audience
 * matters more than raw naturalness in European languages.
 */

/** Per-provider voice names for the five languages this app speaks. */
const AZURE_VOICES = {
  ar: { female: 'ar-MA-MounaNeural', male: 'ar-MA-JamalNeural' },
  de: { female: 'de-DE-KatjaNeural', male: 'de-DE-ConradNeural' },
  fr: { female: 'fr-FR-DeniseNeural', male: 'fr-FR-HenriNeural' },
  en: { female: 'en-US-JennyNeural', male: 'en-US-GuyNeural' },
};

const GOOGLE_VOICES = {
  // Google has no Moroccan Arabic - ar-XA is pan-Arabic Modern Standard.
  ar: { code: 'ar-XA', female: 'ar-XA-Wavenet-A', male: 'ar-XA-Wavenet-B' },
  de: { code: 'de-DE', female: 'de-DE-Wavenet-F', male: 'de-DE-Wavenet-B' },
  fr: { code: 'fr-FR', female: 'fr-FR-Wavenet-C', male: 'fr-FR-Wavenet-B' },
  en: { code: 'en-US', female: 'en-US-Wavenet-F', male: 'en-US-Wavenet-D' },
};

/** ElevenLabs' own multilingual model handles every language from one voice. */
const ELEVENLABS_MODEL = 'eleven_multilingual_v2';
const ELEVENLABS_DEFAULT_VOICES = {
  female: '21m00Tcm4TlvDq8ikWAM', // "Rachel"
  male: 'TxGEqnHWrfWFTfGW9XjX', // "Josh"
};

const MELOTTS_MODEL = '@cf/myshell-ai/melotts';

/**
 * Synthesizes [text] and returns `{audioBase64, mimeType, provider}`.
 * Throws with a readable message if every configured provider failed, so
 * the deploy smoke test names the one that broke rather than just "502".
 */
export async function synthesizeSpeech(text, lang, env, { female = true } = {}) {
  const language = (lang || 'en').split('-')[0].toLowerCase();
  const errors = [];

  for (const provider of providersFor(env)) {
    try {
      const result = await provider.run(text, language, env, female);
      if (result?.audioBase64) return { ...result, provider: provider.name };
      errors.push(`${provider.name}: returned no audio`);
    } catch (error) {
      errors.push(`${provider.name}: ${String(error?.message ?? error)}`);
    }
  }

  if (errors.length === 0) throw new Error('no TTS provider configured');
  throw new Error(errors.join(' | '));
}

/** Only providers whose secrets are actually set, in preference order. */
function providersFor(env) {
  const providers = [];
  if (env.AZURE_SPEECH_KEY && env.AZURE_SPEECH_REGION) {
    providers.push({ name: 'azure', run: azureTts });
  }
  if (env.GOOGLE_TTS_API_KEY) {
    providers.push({ name: 'google', run: googleTts });
  }
  if (env.ELEVENLABS_API_KEY) {
    providers.push({ name: 'elevenlabs', run: elevenLabsTts });
  }
  // Always last: free and needs no signup, but currently broken upstream.
  if (env.AI) providers.push({ name: 'melotts', run: meloTts });
  return providers;
}

async function azureTts(text, language, env, female) {
  const voices = AZURE_VOICES[language] ?? AZURE_VOICES.en;
  const voice = female ? voices.female : voices.male;
  const locale = voice.split('-').slice(0, 2).join('-');

  const response = await fetch(
    `https://${env.AZURE_SPEECH_REGION}.tts.speech.microsoft.com/cognitiveservices/v1`,
    {
      method: 'POST',
      headers: {
        'Ocp-Apim-Subscription-Key': env.AZURE_SPEECH_KEY,
        'Content-Type': 'application/ssml+xml',
        'X-Microsoft-OutputFormat': 'audio-24khz-48kbitrate-mono-mp3',
        // Azure's TTS endpoint documents User-Agent as required.
        'User-Agent': 'tayarti-voice',
      },
      // The xmlns declaration is NOT optional: without it Azure rejects the
      // request with a bare HTTP 400 and an empty body, which is a
      // singularly unhelpful way to say "your SSML is malformed".
      body:
        `<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='${locale}'>` +
        `<voice xml:lang='${locale}' name='${voice}'>${escapeXml(text)}</voice>` +
        `</speak>`,
    },
  );
  if (!response.ok) {
    const detail = (await response.text()).slice(0, 200).trim();
    throw new Error(`HTTP ${response.status}${detail ? ` ${detail}` : ' (empty body)'}`);
  }
  return {
    audioBase64: bytesToBase64(new Uint8Array(await response.arrayBuffer())),
    mimeType: 'audio/mpeg',
  };
}

async function googleTts(text, language, env, female) {
  const voices = GOOGLE_VOICES[language] ?? GOOGLE_VOICES.en;
  const response = await fetch(
    `https://texttospeech.googleapis.com/v1/text:synthesize?key=${env.GOOGLE_TTS_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        input: { text },
        voice: { languageCode: voices.code, name: female ? voices.female : voices.male },
        audioConfig: { audioEncoding: 'MP3' },
      }),
    },
  );
  if (!response.ok) {
    throw new Error(`HTTP ${response.status} ${(await response.text()).slice(0, 200)}`);
  }
  const data = await response.json();
  // Google already hands back base64 - no re-encoding needed.
  return { audioBase64: data?.audioContent, mimeType: 'audio/mpeg' };
}

async function elevenLabsTts(text, language, env, female) {
  const voiceId =
    env.ELEVENLABS_VOICE_ID ||
    (female ? ELEVENLABS_DEFAULT_VOICES.female : ELEVENLABS_DEFAULT_VOICES.male);

  const response = await fetch(
    `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`,
    {
      method: 'POST',
      headers: {
        'xi-api-key': env.ELEVENLABS_API_KEY,
        'Content-Type': 'application/json',
        Accept: 'audio/mpeg',
      },
      body: JSON.stringify({ text, model_id: ELEVENLABS_MODEL }),
    },
  );
  if (!response.ok) {
    throw new Error(`HTTP ${response.status} ${(await response.text()).slice(0, 200)}`);
  }
  return {
    audioBase64: bytesToBase64(new Uint8Array(await response.arrayBuffer())),
    mimeType: 'audio/mpeg',
  };
}

async function meloTts(text, language, env) {
  const result = await env.AI.run(MELOTTS_MODEL, { prompt: text, lang: language });
  return { audioBase64: result?.audio, mimeType: 'audio/mpeg' };
}

/** Chunked so a long utterance can't blow the argument limit of apply(). */
function bytesToBase64(bytes) {
  let binary = '';
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode.apply(null, bytes.subarray(i, i + chunk));
  }
  return btoa(binary);
}

function escapeXml(value) {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}
