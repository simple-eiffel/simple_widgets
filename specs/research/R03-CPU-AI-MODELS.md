# R03 — CPU-only Free AI Models for the simple_* Ecosystem

*2026-08-22 survey; licenses verified against repo LICENSE files and
model cards. Baseline: modern 8C/16T desktop, AVX2, Q4 quantization.
Full tables in the research transcript; this is the decision sheet.*

## The license-clean shortlist (ships beside MIT code)

| Job | Pick | License chain | Shape |
|---|---|---|---|
| Parse/assist in widgets | llama-server + Qwen3-1.7B (upgrade Phi-4-mini 3.8B, downgrade Granite 4.0 Nano 1B) | MIT + Apache-2.0 / MIT | persistent localhost worker, OpenAI-style HTTP, json_schema -> GBNF = guaranteed-valid JSON |
| Dictation into a text box | whisper.cpp + small.en (Vosk for live partials) | MIT + MIT (Apache-2.0) | spawn whisper-cli per utterance or DLL |
| Local TTS | Kokoro-82M int8 via kokoro-onnx + ONNX Runtime; inbox SpeechSynthesis as tier-0 | Apache-2.0 + MIT + MIT (isolate espeak-ng GPL fallback in a worker) | worker exe |
| Semantic search | bge-small-en-v1.5 + ONNX Runtime + sqlite-vec; potion-base-8M for bulk | MIT + MIT + MIT/Apache | 1-4 ms/sentence CPU |
| Spellcheck | Windows ISpellChecker (inbox COM, Win8+) + SymSpell for domain vocab; Harper for grammar | free-inbox + MIT + Apache-2.0 | zero deployment |

## Speed reality (CPU, Q4)

0.6B: 60-100+ tok/s. 1.7B: 30-60. 3-4B: 10-20 (Phi-4-mini is the
strongest MIT model). 7-8B: sluggish. whisper small.en: 2-6x
realtime. Kokoro: 2-5x realtime. Embeddings: 1-4 ms/sentence.

## Traps for an MIT shipper

Qwen2.5-3B (research-only outlier in an Apache family), everything
Gemma (custom terms flow to users), Llama 3.2 (community license,
notices), LFM2 (revenue cap), Piper's active repo now GPL-3.0
(archived rhasspy/piper stays MIT), the espeak-ng GPL chain under
Kokoro/KittenTTS English G2P fallback, Moonshine non-English models.

## Windows inbox (free, offline, CPU)

Windows.Media.Ocr (proven in this stack), SpeechSynthesis voices,
ISpellChecker. AVOID building on Windows.Media.SpeechRecognition
(engine deprecated 2023). Phi Silica: NPU-only, irrelevant here.
Windows ML (24H2+) ships a system ONNX Runtime worth targeting.

## Widget-level AI: the low-hanging fruit, in order

1. SW_TEXT_BOX spellcheck via ISpellChecker: zero models, zero
   licenses, the WinOCR trick again. Squiggle + suggestions into the
   existing context menu.
2. Dictation button on SW_TEXT_BOX: whisper.cpp worker, push-to-talk,
   text lands at the caret.
3. Smart paste (KendoReact's 2025 flagship, ours license-clean):
   clipboard -> Qwen3-1.7B with a json_schema of the form's fields ->
   guaranteed-valid JSON -> fields fill.
4. Semantic find-in-list for SW_LIST/data grid: bge-small + sqlite-vec.
5. narrate tie-in: Kokoro is a serious CPU TTS spike candidate.
