# Reference coverage and implementation status

The supplied manual is Ableton Live 8.0.2, May2009, 534 PDF pages. Every page's extracted text was reviewed across four consecutive reports; selected figures were rendered and inspected. The original PDF is retained in this source package. Review is not feature parity. The device catalog identifies 52 named devices/instruments/library entries; none is claimed as an exact implementation.

**This is an original macOS development preview, not a complete implementation of the manual.** The [macOS validation run](https://github.com/shaunroohi-alt/BeatMeat/actions/runs/40463701686) passed for implementation commit `a69ac23c7bf810eaf378c1fae9e0c4cd7c0817f9`: universal build/type checking/linking, 22 DSP scenarios, 26 Swift persistence/MIDI tests, native project/MIDI/WAV smoke checks, native window/screenshot and audio-graph initialization, architecture verification, ad-hoc signing, and ZIP/DMG packaging. The [v0.1.0-dev release](https://github.com/shaunroohi-alt/BeatMeat/releases/tag/v0.1.0-dev) provides the preview packages.

Physical microphone recording, hardware latency, audible output on a user's device, sustained real-time performance and notarization remain unverified. The table below records the implemented subset and all outstanding reference features; a passing build does not establish feature parity.

| Ch | Topic | BeatMeat source behavior and remaining work |
|---|---|---|
|1|Welcome/new features|Independent BeatMeat identity and original interface; not Live8 feature parity|
|2|First steps|Native workspace, demo MIDI project, app menus and controls; interactive lessons/settings/audio device chooser absent|
|3|Authorization|No vendor license/authorization emulation; app has no online account requirement|
|4|Core concepts|Audio/MIDI tracks share Session/Arrangement state, quantized launches, per-track Session overrides, Back to Arrangement; fixed4/4 and16tracks/8slots limits|
|5|Files and sets|Versioned .beatmeat directory packages, collected audio, save/open, SMF0/1 MIDI import, type0 export, Arrangement WAV export; no .als compatibility, packs/browser/library/cloud media search|
|6|Arrangement|Beat-based clip placement/length inspector, visual timeline, transport looping; overlapping regions sum instead of enforcing Live's single lane; no splits/consolidation/crossfades/multiple instances/recorded Session performance|
|7|Session|8 clip rows, scenes, exclusive Session slot pertrack, quantized stop, explicit return to Arrangement; no launch capture into timeline or per-slot stopbutton configuration|
|8|Clip view|Names, loop, start, length, waveform overview and editable MIDI notes; no separate source offset/region versus loop markers, perclip transpose/gain or sample editor|
|9|Tempo/warp|BPM20–300, native sample-rate conversion; tempo changes timing of source playback positions without pitch-preserving stretching; no Warp markers/modes, tempo maps or complex transient analysis|
|10|MIDI editor|Pitch/start/duration/velocity editing, click-to-add/delete, octave navigation and standard MIDI file interchange; max64notes/clip; no live MIDI capture, steprecord, clipboard transforms or note quantize command|
|11|Grooves|Not implemented: groove extraction/pool/timing/velocity/humanization|
|12|Launch modes|Next-bar4-beat clip/scene launch; no Trigger/Gate/Toggle/Repeat options, follow actions or legato launch|
|13|Routing|Stereo master, pertrack gain/pan/mute/solo, shared delay send, microphone recording into an armed audio track; no arbitrary bus graph, input monitoring, sidechain routing, multichannel outputs, cue bus or CoreMIDI I/O|
|14|Mixer|Track controls, pre-output track meters, lowpass, delay send, persisted master volume; no groups/returns editor, crossfader, calibrated loudness metering, device compensation or MIDI mappings|
|15|Recording|Mic permission and AVAudioEngine capture to temporary CAF, converted into an audio clip on stop; not device-tested; no overdub/punch/preroll/count-in, diskstreaming recorder or Arrangement performance capture|
|16|Devices/plugins|Original sine synth, gain/pan, lowpass and delay; no reorderable chain, AU/VST host, plugin editor, parameter automation or delay compensation|
|17|Racks|Not implemented: instrument/drum/effect racks, zones, macros, parallel chains|
|18|Automation|Undo/redo snapshots for project edits; no recorded/read/edited automation or takeover handling|
|19|Clip envelopes|Not implemented: linked/unlinked envelopes, modulation and independent envelope loops|
|20|Video|Not implemented|
|21|Audio effects|Original lowpass and shared quarter-note delay only; no claim of parity with any of 31 named reference devices; emergency output hardclip is not a transparent master limiter|
|22|MIDI effects|Not implemented: seven reference MIDI device algorithms|
|23|Instruments/libraries|Original polyphonic sine-note renderer; no sampled factory library, modeled instruments, Operator/Sampler/Simpler/Tension/DrumRack or proprietary sound content|
|24|Max for Live|Not implemented; no Max runtime or patch compatibility|
|25|Sharing|Portable self-contained project packages; no Ableton services, online collaboration or cloud upload|
|26|Remote controls|Basic native menu shortcuts; no MIDI learn, key mapping or takeover modes|
|27|APC40|Not implemented; no hardware integration or LED protocol|
|28|Synchronization|Internal tempo/transport only; no MIDI clock/MTC/ReWire/external sync|
|29|CPU/freeze|Preallocated render buffers, bounded PCM, no allocations or locks in C++ render; no freeze/flatten or streaming-media engine|
|30|Audio facts|32-bit samples,64-bit mix accumulation,5ms gain/pan smoothing,22 portable tests; not a Live8 null-test/compliance result; hardclipping/nonbandlimited interpolation differ|
|31|MIDI facts|PPQ note-file codec and deterministic kernel note timing; no measured hardware jitter, timestamps, monitored MIDI recording or driver scheduling|
|32|Shortcuts|Native New/Open/Save/Import/Export/Undo/Redo menus; no exact full Live shortcut set|

## Engineering constraints

- macOS14+; SwiftUI/AppKit frontend, AVAudioEngine output/input, original C++17 renderer. No third-party SDK/runtime downloads are required.
- All source PCM is held in memory. The retained kernel cap is256MiB; decoding a clip and building a replacement kernel temporarily raises peak memory substantially. Rebuilding/loading pauses audio and resets Session override state. This is not a seamless live-performance engine.
- Audio sample-rate conversion is linear interpolation. It is not a bandlimited resampler, Warp algorithm or independent key lock.
- MIDI synthesis is a sine instrument with gated envelopes. No bundled vendor sounds/samples are inferred from a manual.
- The arrangement is the same small set of clip instances shown in Session; no full source/instance/region graph. Unlaunched Session slots can also have Arrangement placements.
- Recording uses a mono/stereo system input tap and AVAudioFile writer. There is no explicit audio device selector or low-latency disk scheduler. Disk failures are logged; hardware behavior remains untested.
- WAV export is44.1kHz stereo Float32, Arrangement-only, with a tempo-derived effect tail. No dither, normalization, sample-rate chooser, cue-monitor export or full mastering path.
- Structural editing is not seamless during playback. Recording blocks structural changes. Recording must be stopped and the project saved to collect its temporary audio.
- All 26 Swift persistence/MIDI XCTest cases passed on the macOS runner. Native smoke checks passed for save/open/overwrite, MIDI roundtrip and non-silent offline WAV export. A native window screenshot and audio-graph initialization check also passed. These checks do not replace interactive workflow, physical recording or audio-device performance tests.
- The universal preview bundles passed ad-hoc signing verification and ZIP/DMG packaging. Developer ID signing and Apple notarization are not configured or verified.

The reference manual documents observable product behavior, not enough information to reconstruct all proprietary algorithms or missing content. The review reports and device catalog are the complete reference roadmap for further implementation.
