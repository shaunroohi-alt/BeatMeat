# Manual review: PDF pages 135–268

Reference: **Ableton Reference Manual Version 8**, Live 8.0.2, May 2009. This is an implementation specification distilled from the supplied reference, not copied app source, an instruction to operate Ableton, or a claim that its algorithms/assets were supplied. Page numbers below are PDF page numbers; printed page numbers are two lower in this range.

## Review inventory and limits

All text on **134/134 PDF pages 135–268** was read sequentially, from the first paragraph on Complex Mode through the start of “Unlinking Clip Envelopes From Clips.” Each page was included in the extracted section and read, including continuation pages, captions, warnings and workflow examples. Key figures were additionally rendered and visually inspected: PDF 176 (routing taps), 196 (seven crossfader-response curves), and 244 (Drum Rack chain/routing layout). Other figures are covered through their captions and associated numbered descriptions; this report does not claim pixel measurements or inspection of every diagram. Several modifier-key glyphs are missing from text extraction. Preserve semantic actions, and verify the original rendered page before promising identical shortcuts.

| Reviewed PDF pages | Printed pages | Source scope |
|---|---|---|
| 135–136 | 133–134 | 9.3.5 Complex, 9.3.6 Complex Pro, 9.3.7 REX |
| 137–141 | 135–139 | 10.1 MIDI creation, 10.2 editor, 10.3 navigation/transport |
| 142–150 | 140–148 | 10.4.1–10.4.11 all MIDI editing subsections |
| 151–156 | 149–154 | Chapter 11, all groove sections and examples |
| 157–165 | 155–163 | Chapter 12, launch modes, quantization, velocity, legato, every follow-action example |
| 166–169 | 164–167 | Chapter 13 introduction, monitoring, audio I/O, mono/stereo, MIDI routing |
| 170–173 | 168–171 | MIDI port configuration, computer keyboard, synths, indicators, ReWire |
| 174–177 | 172–175 | Resampling, internal routing, tap points and Rack taps |
| 178–186 | 176–184 | Every internal-routing use case: post-FX recording, instruments, submixes, multitimbral, sidechain, layering |
| 187–190 | 185–188 | Chapter 14 mixer views, controls and expanded meters |
| 191–194 | 189–192 | Track operations, groups, returns, master, sends |
| 195–199 | 193–197 | Crossfader curves/assignments, solo/cue, track delay |
| 200–206 | 198–204 | Chapter 15 inputs/arm, Arrangement/Session recording, MIDI overdub and step recording |
| 207–210 | 205–208 | Recording sync, quantization, count-in, formats/storage and remote controls |
| 211–218 | 209–216 | Chapter 16 typed device chain, insertion/reordering/bypass/meters and presets |
| 219–224 | 217–222 | Defaults, plug-in activation, host controls/windows/configuration/mapping |
| 225–230 | 223–228 | Plug-in buffers, VST discovery/programs/banks, AU presets, device delay compensation |
| 231–237 | 229–235 | Chapter 17 Rack graph, eight Macros, four Rack types, creation/views/chains |
| 238–243 | 236–241 | Rack Auto Select and key/velocity/chain-select zones and fades |
| 244–248 | 242–246 | Drum Rack routing/chokes/pads and slicing creation |
| 249–252 | 247–250 | Slice effects, Macro mappings, nested mixer and extracting chains |
| 253–259 | 251–257 | Chapter 18 recording/deleting/overriding/drawing/editing automation and tempo automation |
| 260–268 | 258–266 | Chapter 19 clip envelopes through MIDI-controller envelopes and introduction to unlinked loops |

These ranges are contiguous and collectively cover every assigned page, with no omitted pages. The rest of Chapters 9 and 19 are outside this review and require the adjacent reviewers' reports.

## Chapter 9 continuation: tempo and warping (PDF 135–136)

- Complex Mode is intended for mixed/polyphonic sources such as entire songs. The manual estimates approximately **10× the CPU of other modes**, so freeze and rendering to a replacement audio clip are workflow requirements, not merely optimization advice.
- Complex Pro is a distinct, more expensive variation for polyphonic material. Its **Formants** control at 100% preserves source formants when transposing; it has **no effect without transposition**. **Envelope** defaults to **128**, with lower values suggested for high-pitched sources and higher values for low-pitched ones.
- A genuine implementation needs independent time/pitch control and formant behavior, not ordinary variable-speed resampling relabeled “Complex.” The manual does not contain sufficient source code or exact DSP coefficients to reproduce the proprietary algorithms.
- REX is selected by **file format**, not the Warp chooser. Embedded timing follows project tempo. REX supports Slice to New MIDI Track, but **does not expose Warp Markers/parameters, warping-property clip envelopes or clip nudge controls**.
- Acceptance: mode-specific parameter enablement; pitch/formant tests for transposed and unchanged audio; tempo synchronization; predictable freeze/render results; explicit rejection or accurate identification of unsupported REX imports.

## Chapter 10: MIDI notes and velocities (PDF 137–150)

### Representation and creation

A MIDI clip is a nondestructive musical event sequence: **pitch, onset, duration and velocity**, plus controllers, directed either to a virtual instrument on the track or an external synth. The original imported MIDI file is never modified by clip edits. Create clips by recording, double-clicking an empty MIDI Session slot, using Insert MIDI Clip on a selected empty slot, or selecting a MIDI Arrangement time range and inserting a clip. MIDI note edits participate in Undo.

The editor consists of a **Note Editor above a resizable/hideable Velocity Editor**. Draw mode and selection mode have deliberately different semantics:

- Draw mode places/deletes notes; horizontal movement enters notes and vertical movement changes velocity. The last drawn velocity becomes the velocity for subsequent notes.
- Selection mode allows selection, drag-move in time/pitch, double-click add/delete, resizing both note edges, and clipboard operations.
- Preview produces sound when selecting/moving notes or playing the piano ruler; when the track is armed it also enables step recording.

### Navigation and selection

- Horizontal axis is beat time; vertical piano scale is **C0–C10**. Drag the time ruler vertically for time zoom and horizontally for scroll; drag the note ruler vertically for pitch scroll and horizontally for note-height zoom.
- Double-click time/note ruler fits the selected notes/time. With no selection, note fit spans lowest/highest pitch, and time fit spans first/last note. `+`/`−` zoom around the current selection.
- Clip overview always shows complete clip content; its viewport can move, zoom and resize. Follow scrolls with playback. Scrub obeys quantization; permanent-scrub preference governs ordinary clicking versus modifier activation.
- Fold hides rows unused in **any clips on that track**, not only the selected clip. This matters for percussion mappings.
- Clicking a note selects it; rubber-band selects notes; clicking empty space places an insertion point; dragging empty space selects a time range. Return selects notes beginning in the selected range. Escape deselects notes.
- Cursor navigation can move by grid, next note boundary, start/end, and extend a selection from either edge. Selection supports adjacent/nonadjacent additions, toggles, all notes of one pitch, next note at same pitch or next note in time.

### Editing rules and edge cases

- Snapping includes **grid plus original note offset**, preserving a loose/grooved note's relative offset. A modifier temporarily bypasses snapping.
- Move changes onset/pitch; octave transpose is separate from semitone move. Left/right note-edge resizing is selection-mode only and snapped unless temporarily bypassed. Multi-note resizing is supported.
- Paste begins at the insertion point. Modifier-drag copies notes; the modifier may be pressed after drag starts.
- Same-pitch overlapping insertion has destructive conflict semantics within the clip: if a new note overlaps the **start** of an original, the original disappears; if it overlaps only the **tail**, the original ends at the new note onset. This must not produce stuck notes.
- Cut/Copy/Paste/Duplicate apply to selected notes or notes in the selection. **Time operations are separate**: Cut Time and Delete Time close the gap; Paste Time and Duplicate Time insert time; Insert Silence inserts the selected duration before the selection. **They do not alter clip start/end or loop-brace settings.**
- Quantize may use visible grid or an explicit meter division; target note starts, ends or both. End quantization changes note length. **Amount** interpolates partially toward the target rather than always hard-snapping.
- Velocity lane markers correspond to notes, highlight with note hover, show numeric values, and support multiselection. In draw mode velocity edits apply only to selected notes and may set identical values per tile; disabling grid permits individual ramps. A line gesture can create a linear velocity ramp across selected notes. Note brightness encodes velocity.
- Support both **note-on and note-off velocity** as distinct fields. Release velocity is consumed only by instruments that support it; do not silently equate it with ordinary velocity.
- Stretch Notes appears only for a multi-note selection. Start/end stretch handles proportionally scale timing and duration; handles snap unless bypassed. Crossing handles reverses event order (retrograde). **Concurrent note changes, including incoming overdub notes, cancel an in-progress stretch.**
- Crop MIDI Clip removes unused MIDI data **without creating a new disk file**. Note deactivation is persistent mute, distinct from deletion, and may target individual notes or all notes of one pitch.

### Required regression cases

Imported file byte integrity after edits; all 128 MIDI pitches; simultaneous same-pitch notes; overlap-tail truncation versus start replacement; partial start/end quantization; note-off velocity round trip; transpose and clipboard timing; time edit leaving loop bounds unchanged; offset-aware snap; reversible stretch and cancellation during overdub; preview/step-record modes without stuck note-offs; Undo restoration of edits.

## Chapter 11: grooves (PDF 151–156)

Grooves are reusable **timing and velocity patterns**, not a swing knob only. Audio grooves require Warp enabled; MIDI grooves operate on event placement. Grooves may be loaded by dragging `.agr` material to a clip or directly to a **Groove Pool**. The pool includes used and explicitly loaded grooves; unused entries are shown inactive/grey, not deleted. Hot Swap permits audible comparison during playback.

Each groove includes:

- **Base**: subdivision used to compare each source event to its nearest grid position; e.g. quarter versus eighth changes which timing offsets apply. Events exactly on that grid have zero groove displacement.
- **Quantize**: amount of straight pre-quantization before applying the groove, **0–100%**.
- **Timing**: depth of groove timing displacement.
- **Random**: per-voice timing randomization. Simultaneous chord notes may separate from each other; it is not one common offset per chord.
- **Velocity**: **−100% to +100%**, with negative values inverting the groove's accents.
- **Global Amount**: scales Timing, Random and Velocity for every groove; can reach **130%** for exaggerated application. It does not stand in for the per-groove parameters.

**Commit** writes the result into the clip: MIDI note positions/velocities or audio Warp Markers. It then clears the clip's groove assignment to **None**, avoiding double application. Extract Groove uses only the clip's **playing region**, from either audio or MIDI. Dragging a groove into a MIDI track exposes it as an editable MIDI clip, which can be re-extracted.

Examples define important use cases: extract an individual drum chain for independent snare feel; non-destructive quantization by setting Timing/Random/Velocity to zero and only using Base/Quantize; humanized doubling using separate randomly displaced copies. Own groove files/presets may be produced, but the manual does not include the actual licensed groove library assets.

Acceptance: deterministic seeded-render option for tests; per-voice random offsets; correct signed velocity depth; 130% global depth; extraction excludes out-of-region events; commit is undoable and clears assignment; waveform remains untouched on disk.

## Chapter 12: launching clips (PDF 157–165)

These controls apply to **Session** clips. Arrangement clips obey placement on the timeline instead and have no launch box. Multiple selected clips may have launch settings edited together.

### Input and scheduling semantics

| Mode | Input down | Input up / later input |
|---|---|---|
| Trigger | Starts/retriggers clip | Release ignored |
| Gate | Starts clip | Release stops clip |
| Toggle | Starts if stopped | Release ignored; next down stops |
| Repeat | Triggers at clip quantization rate while held | Release ends repeated triggering |

Clip onset quantization is **None**, **Global**, or an explicit subdivision. None starts immediately. Global inherits the transport setting. Other values override it. MIDI launch velocity modulates clip volume using a separate amount: zero amount ignores velocity; at 100%, minimum/softest input may render silence.

**Legato** transfers the track's current clip **play position** to the newly launched clip, allowing changes without phase reset even with no quantization. Different sample files may cause unexpected disk reads/dropouts; preloading/RAM mode is a mitigation. It is not equivalent to restarting every clip at its beginning.

### Follow-action model

A group is a **contiguous run of occupied slots in one track**, separated from other groups by empty slots. A clip stores a follow time in bars/beats/sixteenths relative to its **launch start**, two action choices A/B, and relative chance weights A/B. Weight zero makes that choice impossible; weights are relative (1:10 is approximately 1/11 versus 10/11). Default is one bar and effectively No Action.

Actions: Stop, Play Again, Previous, Next (wraps at group end), First, Last, Any, Other (excludes self when another member exists), plus No Action. Stop overrides clip loop/region settings. A one-member group using Other must not crash. Follow times are exact unless an **explicit clip quantization** delays the transition: **follow actions bypass Global quantization, but not a non-Global explicit clip quantization.** This exception is important when sharing the ordinary launch scheduler.

Examples cover: non-looping introduction followed by an indefinitely looping tail; cyclic sequences with occasional random transitions; probabilistic repeating first bar followed by continuing the rest when No Action wins; legato variation without phase disruption; long-running nonrepetitive installations using odd follow durations. A scheduler therefore needs sample-stable long-duration transport, RNG state, cancelable pending launches/stops, and recording of actual resulting clip activity into Arrangement when recording is enabled.

## Chapter 13: routing and I/O (PDF 166–186)

### Track signal types and monitoring

The shared track model must represent source/destination **type** and **channel** as two levels. Audio tracks receive audio. MIDI tracks receive MIDI and output MIDI until an instrument converts it into audio. Return tracks receive send buses. All routing controls must update the same tracks in Session and Arrangement, with multi-selection operations supported.

Monitoring is a three-state policy, not a Boolean:

- **Auto** (default): input monitoring on while armed, **suppressed while a clip is playing**.
- **In**: always input monitor regardless of arm/clip state, and **suppress clip output**; can make a track act as an auxiliary input channel. The manual indicates this state using an orange activator.
- **Off**: input is still recordable, but not routed audibly through the track. Supports acoustic/direct hardware monitoring without software latency.

Source selection lists available channels and input-activity/overload meters. Device setup determines which physical inputs/outputs are available and exposed as mono or stereo pairs. Record a mono file for a selected mono input and stereo for a stereo input; the device chain is **always stereo**. Mono becomes dual-mono; stereo-to-mono output is **(L+R)×0.5** (−6 dB attenuation of summed channels).

### MIDI, keyboard and external systems

- Per-port **Track** enablement controls whether that input/output appears as a playable routable port. Select one port or merged **All Ins**, and one MIDI channel or merged **All**. Any number of ports may be active.
- Computer MIDI keyboard: central letter row plays white keys from **C3**, upper row black keys. Z/X transpose octaves; C/V change velocity by 20; B is a held +20 accent clamped at 127 (120 becomes 127). Enabling it consumes keys that might otherwise trigger keyboard mappings; expose an explicit toggle.
- External synth output chooses port and channel. Local Off on a keyboard synth avoids direct-plus-software duplication; this is a user hardware setup warning, not a way for the app to disable unknown hardware automatically.
- Three LED pairs distinguish sync clock/timecode, remote mappings and track MIDI; each pair distinguishes received from sent messages. **Remote-mapped messages are consumed and do not also pass to MIDI tracks.**
- ReWire examples describe master/slave MIDI-out/audio-return routing and require startup/order awareness. This is a legacy integration capability, not implementable merely by naming a menu item; current API/licensing/platform feasibility must be checked separately.

### Internal graph and tap points

Two routes have distinct graph meanings:

1. Source output routes to a destination: many-to-one summing; the destination's own input setting remains unchanged. Solo of destination preserves contributors. Solo of one contributor passes that contributor through the destination while muting its peers.
2. Destination input taps source: one-to-many fanout without changing source routing.

Taps are **Pre FX** (raw clip/input before device chain/mixer), **Post FX** (after devices before track mixer), **Post Mixer** (after pan/fader/activator). Pre/Post FX solo handling preserves the tapped signal; **Post Mixer solo can mute the source**. Rack chains expose equivalent taps, including drum-return chains. The PDF 176 figure confirms these are actual chooser options, not three user-facing copies of one endpoint.

MIDI source tapping reaches the **last MIDI stage before the instrument**, even if the source track's final output is audio. This permits layered instruments to consume the same processed MIDI.

### Resampling, sends and examples

- A track may record Master output as **Resampling**. During resampling its **own output is suppressed and excluded from the recorded master**, preventing recursive feedback. Recordings are stored under project `Samples/Recorded`; unsaved sets use the temporary folder.
- Post-FX input recording: one monitored input track performs effects; separate record tracks tap Post FX and use Monitor Off. Post Mixer additionally commits source pan/fader moves.
- Instrument audio printing: audio tracks tap the audio result of a MIDI instrument.
- Submix: several track outputs feed a common audio track or Group Track, then Master.
- Several MIDI tracks may target one instrument directly by device/channel, bypassing the target track's record/monitor input. This differs from routing to **Track In**, and target muting still affects its audio output.
- Multi-output instruments expose individual outputs; the built-in Impulse removes a tapped output from its main internal mix, **but this is not universal plug-in behavior**. Do not impose it on third-party instruments.
- Multitimbral plug-ins have independently addressed MIDI channels and auxiliary audio outputs. An External Instrument device can pair a selected MIDI destination with a selected auxiliary audio return in one track; only secondary outputs are available this way.
- External sidechains route a source track to a target device's sidechain endpoint. Some built-in effects expose an integrated source chooser; third-party plug-ins may require explicit output routing.

Graph acceptance: compatible type validation; explicit feedback policy; cycle detection or bounded feedback behavior; correct node execution order; deterministic fan-in/fan-out; no resampling self-feed; instrument boundary-aware MIDI taps; silence/solo tests at each tap; saved stable IDs rather than UI row indices.

## Chapter 14: mixer and track organization (PDF 187–199)

Session and Arrangement are **two views of the same tracks**, not independent mixers. Session has vertical strips; Arrangement mixer appears beside expanded track lanes. Tab changes view. I/O, Sends, Returns, Mixer, Track Delays and Crossfader visibility are independently configurable **per view**.

- Meter shows RMS and peak of output, but input while monitoring. Expanded Session mixer adds ticks, numeric fader, resettable peak hold, and a dB scale when wide enough.
- Floating-point internal signal flow permits headroom above 0 dB; red internal meters are warnings, not instructions to hard-clip each track. Physical outputs and integer/file conversion must avoid clipping.
- Volume/pan/activator/solo/arm support multi-selection. Relative differences among selected fader/knob values are preserved during common adjustment.
- Exclusive Solo/Arm defaults may be overridden with modifiers or preferences. Inserting an instrument into a new/empty MIDI track can auto-arm when Exclusive Arm is enabled. Arming selects the track.
- Track operations include add by menu/drag/load, rename, user info, drag reorder, resize, select adjacent/nonadjacent, delete, save as a reusable Set. `#` in a name generates a dynamic track number; repeated `#` pads zeros. Dragging nonadjacent tracks gathers them; keyboard reordering may preserve spacing.

### Groups, returns and Master

Groups are foldable **summing containers**, hold no clips directly, and support mixer controls/audio effects. Child routes default to Group **unless already custom-routed**. Group may be merely a folder when child outputs route elsewhere. Deleting group deletes contents; Ungroup preserves individual tracks. Arrangement group shows content overview. Session group slots launch/stop/select all applicable child clips.

The manual provides **one Master** and up to **12 return tracks**, neither hosting clips. Track/group sends feed returns, potentially shared by many tracks. Return **Pre/Post** chooses whether the send precedes or follows the source mixer (including activator, fader and pan). Return-to-return/self sends are **disabled by default** and explicitly enabled because feedback can become hazardous. Master is the default final destination and supports processing.

### Crossfader

Seven named curves are illustrated on PDF 196: **Transition, Dipped, Intermediate, Constant Power, Slow Fade, Slow Cut, Fast Cut**. The reference gives curve diagrams but not numerical formulas; exact equivalence needs measured curves. Each track, including returns, chooses A, B or unassigned. This is a gain/VCA influence **without changing signal routing**. In the manual's assignments, A remains unattenuated across the left half and fades toward mute at the far right; B is symmetric; unassigned remains unaffected. Crossfader and assignment changes can be automated. Continuous absolute/incremental mapping and special left/center/right key toggle/snapback mappings exist.

### Solo, cue and delay

- Solo retains track pan. **Solo in Place** keeps sends/returns audible for a soloed source. Soloing a return mutes other direct outputs but preserves signals reaching it through sends.
- Cue is distinct from Solo and requires **four physical outputs / two stereo output pairs**, with separate Master Out and Cue Out. Cue switches replace Solo buttons; track activator still controls Master output. Browser preview also goes to Cue. Cue Volume is separate. A two-channel headphone split is not equivalent.
- Per-track delay may be positive or negative in milliseconds, distinct from plug-in compensation. It can click if changed live and becomes unavailable when device delay compensation is disabled. Very large values/plug-in latencies increase system response time; compensation normally stays on.

## Chapter 15: recording (PDF 200–210)

### Shared input/arm model

Record the source selected in I/O, not hard-coded microphone input. Audio defaults to external stereo 1/2; MIDI defaults to all active inputs including the computer keyboard. Other inputs include mono/stereo hardware, specified MIDI channels, ReWire, and internal track taps. Arm is common to both views, defaults exclusive, supports modifiers/multi-selection, selects the track and can lock supported controller surfaces to the instrument. Input monitoring follows the policy above and does not determine whether data is recorded.

### Arrangement recording

- Global Record plus Play starts recording and creates clips on **all armed tracks**.
- MIDI Overdub adds to existing notes; overdub does **not** apply to audio tracks in this description.
- Punch In/Out use the Arrangement **loop start/end** as boundaries; these can protect content during preroll or limit the record range.
- Loop recording retains **every audio pass**, not only the visible final pass. The new clip points at the final pass but earlier passes remain accessible by shifting its sample region or Undo. Storage cannot overwrite the same audio file region each loop if claiming this behavior.

### Session recording

- Quantized recording into an empty armed slot produces correctly bounded clips; an empty armed slot displays a record button.
- Record begins in that slot; pressing its launch button ends recording and immediately loops the result. Stop leaves it silent.
- Scene launch does **not** record empty armed slots by default; **Start Recording on Scene Launch** is an explicit preference.
- MIDI pattern overdubbing: create a one-bar clip (adjustable), arm, launch, and add notes while it loops. Turning Overdub off permits rehearsal without recording; turning it back on resumes adding notes. Undo removes the last take and live note editing remains possible.
- A modifier-assisted empty-slot creation also arms/launches.

### Step recording, synchronization and quantization

Step recording needs an armed MIDI track, editor Preview on and insertion position. Advance inserts held notes for a grid step and extends them while held; reverse removes just-recorded held notes. Navigators may be mapped to pedals.

Tempo may change before, during or after recording while clips stay musically synchronized. Metronome starts with transport/clip launch and its level uses Preview Volume. Count-in delays recording, displays **negative bars/beats/sixteenths**, and reaches 1.1.1 at record start. Count-in is not applied when externally MIDI-synced or a ReWire slave.

Record Quantization is normally a **separate Undo step**, so undoing it restores raw recorded timing without removing the take. For ordinary Session/Arrangement recording it cannot change mid-recording. In **looping MIDI overdub**, changes apply immediately and are **not separately undoable**. Post-record quantization remains possible.

File type and bit-depth preferences govern new audio recordings. A default Warp Mode for recordings is configurable. Audio goes to project `Samples/Recorded`, or the configured temporary location before the Set is saved; disk-space handling is therefore a functional requirement. Remote mapping covers global record/play, arms, slot record/launch, relative scene selection and step-record navigators.

Acceptance: true input samples reach disk; permission/input absence is a visible error; monitor Off still records; punch boundaries exact; multi-arm writes independent files; no accidental feedback; audio loops preserve earlier passes; raw MIDI timing survives separate quantization Undo; disk-full failure preserves recoverable data; no false “recording” badge without capture.

## Chapter 16: devices, plug-ins and compensation (PDF 211–230)

### Typed device chain

Three device categories determine valid topology: **MIDI effects transform MIDI**, **instruments transform MIDI to audio**, **audio effects transform audio**. A MIDI track may contain MIDI effects → instrument → audio effects. An audio track may contain only audio processors. Audio effects after a Rack receive its summed output. Devices process serially **left to right**, and ordering changes sound.

The selected track's device view supports insert by browser double-click/Return/drag, append, move between tracks, reorder, cut/copy/paste/duplicate, delete, fold/unfold and user info. Pasting inserts before selected device; selecting final empty area appends. Dropping an audio sample on a MIDI device area creates a sample instrument. Inserting an instrument usually auto-arms for live input. Structural edits should not interrupt streaming. Device activator bypasses processing and removes processing CPU where possible, rather than just drawing a dimmed control. Inter-device meters localize silence/gain errors and float signal flow retains headroom.

### Presets/defaults

Devices save parameter states and user info as reusable presets. Browser folders organize them; Hot Swap temporarily binds browser audition to an existing instance, including replacement by another device, then exits on Escape/close/changed view. Defaults are overrideable per device with overwrite confirmation. Sample-dropping defaults and slicing defaults are separate preset categories; slicing defaults can contain a Rack, sampler and mappings. Saving a preset must not accidentally change the active project or overwrite a default without confirmation.

### Plug-in host behavior

VST and macOS Audio Units need discovery/activation, instrument/effect classification, compatible architecture checks and rescan. Sources are optional and initially inactive in the manual. Plug-in insertion follows the same typed chain rules. Multi-I/O and sidechains are graph endpoints; state must round-trip with the Set.

The native editor and host parameter panel are **synchronized views**. For fewer than **32** published parameters, Live 8 shows all as sliders; larger devices start with a configurable empty panel. Users may add, remove and reorder exposed parameters; warn before removing parameters with automation/envelopes/mappings. Unsupported unpublished parameters cannot be invented. Per-instance configured parameter lists persist with project state. An X–Y pad may map two parameters.

Parameter gestures in native editors may temporarily expose that parameter in automation/modulation/X–Y choosers; automation edits or mappings make it permanent. During recording, moved plug-in parameters are recorded and added to the host panel. Native editor preferences include auto-open, multiple windows, auto-hide on track selection and show/hide-all. Parameter updates must originate safely across editor/audio threads.

VST source scanning supports system/custom locations and alias folders; a scan crash identifies and, after repeated failure, disables the problematic plug-in until reinstall. This strongly implies isolated scanner processes and a quarantine database rather than instantiating unknown plug-ins in the main app without protection. VST programs/banks are **per instance**, different from globally reusable host presets; support import/export and program naming only if actually implemented. The manual's PowerPC/Intel warning is historical; modern BeatMeat must check Apple Silicon/Intel compatibility instead.

AU `.aupreset` assets are organized under `~/Library/Audio/Presets/<Manufacturer>/<Plug-in>` and some factory presets are read-only. Certain quality/mode selectors are available only in the native editor.

Plug-in processing block size may match the hardware or trade greater latency for performance. **Device delay compensation** is enabled by default and covers built-in/third-party instruments, effects and returns. The compensation graph must align paths using reported latency while minimizing live-input latency; a mere fixed global delay does not satisfy this. Large track delays/plug-in latencies can degrade responsiveness and add CPU. Older project compatibility is described but a new independent app need not imply it reads proprietary legacy Set files.

## Chapter 17: Racks (PDF 231–252)

### Graph and four types

A Rack is a reusable, arbitrarily nestable graph object that behaves as **one device** externally. Within it, parallel chains receive the same input and independently process their serial devices, then sum. A Drum Rack differs: each chain selects an incoming note rather than receiving every note.

- MIDI Effect Rack: MIDI effects only; MIDI track placement.
- Audio Effect Rack: audio effects only; audio signal placement.
- Instrument Rack: MIDI effects → instrument → audio effects, per chain.
- Drum Rack: instrument-style chains plus up to **six internal audio return chains** and sends.

Create an empty Rack or group selected devices/chains, including nested grouping. Ungroup dismantles the container while preserving meaningful devices. UI hierarchy must distinguish whole-Rack selection from child-device selection. Views independently show Macros, chains, devices and—for drums—pads. Chain selection drives visible device chain; multi-selection supports organization. Context navigation exposes the full nested tree.

Chains have activator, solo, preset Hot Swap, name/color/info, and—when carrying audio—volume/pan. Drum chains also have sends and MIDI assignment. Auto Select chooses processing chains; for drums, the received note selects its chain; for other Racks, zones determine eligible chains.

### Zone filtering and fades

Instrument/MIDI-effect chains filter on **key, velocity and chain-select zones**, and an event must pass **all three**. Audio Effect Racks have chain-select zones but not key/velocity zones. Drum Racks have no zone editor; their receive-note choices implement filtering.

- Key zones span the MIDI range, with optional velocity attenuation through fade ranges.
- Velocity zones span note-on velocities **1–127** and also attenuate velocity through fades.
- Chain selector spans **0–127**, default one-unit-wide zone at zero. Distinct ranges form a switched preset bank; overlapping fade ranges crossfade preset banks.
- By default Instrument/MIDI-effect chain-select zones filter **notes only**; a separate option also filters controller messages.
- In MIDI Effect Racks, chain fades attenuate incoming velocities. In audio-output Racks, fades attenuate **chain output audio**.
- Leaving a zone with a fade range attenuates existing audio to zero; leaving a zone **without** a fade range permits effect tails to decay naturally. This requires distinguishing “reject new events” from “kill active voices/tails.”

### Drum-specific routing/pads/slicing

Drum chain Receive chooses a MIDI note (with number/name/GM label), Play chooses the remapped outgoing note, and **16 choke groups** enforce mutual silence. Choosing All Notes disables Play/Choke and passes incoming notes unchanged. Preview sends a note into a chain. Sends are post-fader to up to six internal returns; a return may output to Rack sum, Set returns, or an ancestor Rack return when nested.

Pad View represents **notes**, not necessarily one chain: 128 MIDI notes are pageable by octaves or single rows. Sample drop into empty pad creates sampler/chain; adding effects preserves the instrument; replacing a sample preserves surrounding effects. Multi-sample drop maps chromatically, while modifier-drop layers them into a nested Rack on one note. Dragging pads swaps note mappings, which intentionally changes sounds triggered by existing MIDI notes; modifier-drag layers. Multiple eligible chains display **Multi**; pad mute/solo/preview applies to all, while rename/Hot Swap is disabled for mixed chains. Supported pad controllers follow the currently visible pad bank.

Slice to New MIDI Track preserves source audio and divides by beat resolution, transients, Warp Markers or REX embedded timing. Reject configurations with **more than 128 slices**. It creates a MIDI track/clip, one ascending note per slice with original timing, and a Drum Rack chain/sample region per slice. A selected slicing preset may pre-map Macros across every sampler. Slices can then be resequenced, remapped or processed independently.

### Eight Macro controls and nested mixing

Every Rack has **eight** Macros. Mapping can target any number of parameters; each mapping stores min/max, including inverted min>max. A singly mapped Macro adopts target name/units; multiple mappings use generic name and a **0–127** scale unless units/ranges are identical. Mapped target controls become directly disabled but remain externally modulatable by clip envelopes. Macro mappings are editable/deletable and each Macro has name/color/info.

Instrument/Drum Rack chains may unfold alongside tracks in Session mixer, nested recursively, without clip slots. Chain-list and mixer controls refer to the **same model**. Multiselect-relative mixer changes apply from Session mixer but not identically from chain list. Extracting a drum chain **from the mixer** creates a track with its devices **and relevant MIDI notes**; extracting from the chain list moves devices only. Extracting a Rack return may create a Set return track.

## Chapter 18: Arrangement automation (PDF 253–259)

Automation is a time-varying **absolute value** for a control across the song, including tempo. Moving controls while global Record is enabled records automation. Automated controls show a state indicator. Delete Automation removes the envelope and leaves the current control static. Manual movement outside Record **overrides** existing automation without erasing it; **Back to Arrangement** indicates a divergence and restores all written automation when pressed.

Automation lanes may overlay clips or appear in independently hideable lanes. Control interaction selects its envelope. Device/control choosers mark automated parameters and may filter to automated only. Hiding a lane does **not** deactivate its envelope. Switches and enumerated parameters use discrete envelopes.

Draw mode writes grid-width steps; hide grid or use a modifier for freehand. Selection mode edits breakpoints/segments: double-click line inserts, double-click point deletes, drag moves selected points with neighboring-point constraints; a wipe modifier permits replacing crossed points, and a fine modifier improves resolution. Dragging a segment vertically inserts boundary points so changes remain within the selected timespan.

By default, moving a clip moves associated automation. **Lock Envelopes** instead holds it at song positions. Editing a dedicated lane affects only its selected envelope(s); editing clip-track selection affects clip and all associated envelopes. Envelopes may be copied between unrelated parameters, so normalization/range conversion behavior must be explicit.

Tempo automation resides on Master → Mixer → Song Tempo. Min/max displayed tempo values scale the editor and also constrain the mapped MIDI-controller tempo range. Time conversion and export/render must follow the actual tempo envelope, not assume a constant samples-per-beat everywhere.

## Chapter 19 beginning: clip envelopes (PDF 260–268)

Clip envelopes share breakpoint editing gestures with Arrangement envelopes but have different semantics. Audio clip choices include sample controls, track effects and mixer. MIDI clips expose MIDI controllers and device parameters. Changed-envelope indicators, modulated-only filtering and quick choosers aid navigation. Deleting all points restores the default. Copying a loop-brace-selected region and pasting one loop-length later repeats an envelope. Multiple clip variations may reuse the same unchanged source audio; rendering/resampling/consolidation commits new audio only when requested.

- **Transpose** modulation is **additive** to the clip's base transpose and clamped to **−48…+48 semitones**. Warp algorithm/grain/transient settings affect response speed.
- **Clip volume** envelope is a **relative percentage** of the base clip volume, can attenuate to silence but not exceed the absolute setting.
- **Sample offset** is available in **Beats Warp Mode only**, measured in sixteenths, with **±8 sixteenth-note** range. Positive goes to future source position and negative to past. Shapes may repeat/reorder/slur beats; it is not destructive cut/splice editing.
- Replacing the sample by dropping a new source into the clip editor **preserves all clip settings/envelopes**.
- Arrangement automation supplies absolute mixer/device values; clip envelopes **modulate those values relatively**, allowing simultaneous operation. **Clip Volume** is pre-device/sample gain; **Mixer Volume** affects the post-device track gain stage.
- Mixer/send envelopes cannot exceed their base controls; volume/send may reach negative infinity. UI shows effective gain with a dot/ring rather than moving the base-control knob misleadingly.
- Pan modulation depends on base pan: full modulation range at center, reduced as base approaches either edge, and no remaining modulation at a hard-left/hard-right base position.
- MIDI controller envelopes are event values rather than relative audio parameter modulation. Support controllers through **119**, with imported/recorded data editable. Device-specific CC behavior may differ from conventional labels.
- The last page introduces independently looping clip-envelope regions; detailed unlinked-envelope behavior continues beyond PDF 268 and is not fully specified by this section alone.

## Cross-cutting implementation priorities

1. **One shared model and stable IDs:** Audio/MIDI/group/return/master tracks; clips with region/loop/launch settings; immutable source references; notes with note-on/off velocity; typed device graph; lanes/envelopes; presets and mappings. Session and Arrangement must never have independent mixer state.
2. **Beat-domain scheduler:** Samples↔beats conversion; launch quantization, legato takeover, follow timers/chance, count-in, loop and punch transitions; correct tempo-envelope handling; cancellation on stop/seek/project change.
3. **Typed graph first:** Source/tap/routing identities, audio/MIDI boundaries, pre/post stages, sends/returns and explicit safe feedback; later multi-I/O plug-in and Rack expansion must fit this topology.
4. **Nondestructive project editing:** Imported files immutable, history snapshots/commands, separate MIDI quantize Undo, loop-record take retention, relative modulation versus absolute automation, clip/automation move-lock behavior.
5. **Real recording and truthful status:** Only show recording when capture is active; prepare storage/input permissions; retain recoverable data and useful failures. Internal engine tests alone do not establish microphone capture or device timing.
6. **Plug-ins are a subsystem:** Scanner isolation/quarantine, architecture compatibility, state persistence, parameter gestures, editors, bus layouts, latency compensation. Merely listing installed components is not hosted playback.
7. **No claimed parity without evidence:** The manual's crossfader plots, warping modes, devices and presets do not supply exact DSP/source/assets. Record each independent implementation and every unsupported mode explicitly; do not present a generic resampler, single synth or handful of effects as full Live 8 equivalence.

## Suggested acceptance matrix for a first verifiable build

| Capability | Test that can fail meaningfully |
|---|---|
| MIDI clip editor | Add/move/resize/quantize/deactivate notes, Undo, save/reopen; original MIDI file stays identical |
| Session launch | Compare exact onset sample for None/Global/explicit quantization; Gate release and Toggle second press; Legato preserves beat position |
| Follow actions | Fixed-seed weighted A/B selections; contiguous-group boundaries; Next wraps; Other excludes self; explicit quantization exception |
| Mixing | Muting and solo dependencies; pre/post send tap difference; same controls reflected between views; internal float headroom preserved |
| Routing | PreFX/PostFX/PostMixer effects and fader dependence; source MIDI tap before instrument; reject invalid type routes; resample excludes its own output |
| Recording | Real captured audio file with expected duration/content; monitor Off still records; punch and count-in boundaries; retained loop passes; MIDI overdub Undo |
| Automation | Record, manually override without erase, restore; audible saved curve; clip movement with/without envelope lock; tempo ramp render alignment |
| Clip envelopes | Relative volume cannot exceed base; additive transpose clamp; sample offset disabled outside Beats; effective-pan range shrinks at hard-pan |
| Racks | Parallel summing, nested state save, note/velocity/selector conjunction, tail behavior, 16 chokes, eight Macros with inverted ranges |
| Plug-in hosting | Instantiate a real AU instrument/effect, process audible input, edit published parameter, save/reopen state, editor UI sync, latency alignment |
| File/deployment | Project portability, missing media error, native macOS compile, actual app launch, audio device playback, signed/notarized status separately reported |
