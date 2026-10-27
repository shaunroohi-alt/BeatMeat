# Manual review: PDF pages 403–534

Source: uploaded **Ableton Reference Manual, Live 8.0.2, May 2009**. The supplied PDF has two front-matter pages before printed page 1; consequently **PDF page = printed page + 2** throughout this range. All page references below use PDF page numbers unless a printed page is explicitly named.

This is a functional specification extracted from reference material, not a statement that BeatMeat implements it. Instructions in the reference to purchase, authorize, contact Ableton, install vendor libraries, configure hardware, or use third-party accounts were read as descriptions of the original product. They are not actions authorized for BeatMeat. The manual does not supply source code, licensed sample data, mathematical implementation details for the proprietary instruments, vendor account access, controller firmware, or performance evidence for BeatMeat.

## Review coverage and inventory

Every extracted text passage in PDF pages **403–534 inclusive** was read, including the index. Page ranges below partition that entire span without omissions. Instrument UI figures were interpreted using their accompanying prose. Keyboard modifier glyphs are lost in the PDF's text extraction; rendered PDF pages **510, 519 and 520** were additionally inspected to verify the principal native-Mac view, grid, quantization, file and device shortcuts. Other shortcut rows are recorded by command family below rather than guessing a missing glyph. Rendered pages **488, 506 and 507** were also inspected:488 confirms a distinct crosshatched Arrangement freeze-tail region adjacent to its source clip;506 confirms an electrical MIDI splitter feeds parallel MIDI recording and zero-latency MIDI-to-audio recording;507 confirms the outgoing MIDI converter path and direct audio-reference path converge at a separate recording instance. These are diagrams/screenshots in addition to the three rendered shortcut tables. This is not a pixel-by-pixel reproduction of every screenshot.

| PDF pages | Printed pages | Material reviewed | Required distinction |
|---|---:|---|---|
| 403–409 | 401–407 | Chapter 23 continuation: Operator complete parameter reference | Section begins before this review range; do not call these seven pages all of Operator |
| 409–410 | 407–408 | 23.9 Orchestral Strings/Brass/Woodwinds/Percussion | Licensed separately installed sample libraries, not audio material included in the PDF |
| 411–423 | 409–421 | 23.10 Sampler | Multisampling, three zone filters, sample playback and modulation |
| 424–426 | 422–424 | 23.11 Session Drums | Separate licensed samples; Drum Rack workflow and microphone/return routing |
| 427–431 | 425–429 | 23.12 Simpler | Single-sample synthesis and CPU behavior |
| 432–446 | 430–444 | 23.13 Tension; start of 23.14 EIC | Physical-model behavior description, not the model's equations |
| 446–448 | 444–446 | 23.14 Essential Instrument Collection | Licensed multisamples and preset quality variants |
| 449–450 | 447–448 | Chapter 24 Max for Live | Separate extensibility runtime and patch editor |
| 451–454 | 449–452 | Chapter 25 Sharing Live Sets | Vendor cloud workflow and cache semantics |
| 455–467 | 453–465 | Chapter 26 MIDI and Key Remote Control | MIDI port setup, takeover, learn, ranges and relative messages |
| 468–478 | 466–476 | Chapter 27 Using the APC40 | Controller layout, banks, feedback and navigation, not hardware supplied |
| 479–484 | 477–482 | Chapter 28 Synchronization and ReWire | Distinct MIDI Clock, MTC and ReWire protocols |
| 485–490 | 483–488 | Chapter 29 Computer Audio Resources and Strategies | CPU scheduling, freeze/flatten, disk overload |
| 491–501 | 489–499 | Chapter 30 Audio Fact Sheet | Quantifiable neutrality and rendering requirements |
| 502–509 | 500–507 | Chapter 31 MIDI Fact Sheet | Timing goals, timestamp strategy and hardware limitations |
| 510–521 | 508–519 | Chapter 32 Keyboard Shortcuts | Twenty command-family sections and context-sensitive editing |
| 522–534 | 520–532 | Complete A–V index | Cross-references to previous chapters; no additional W–Z pages are present in the supplied PDF |

## Chapter 23 continuation: instrument reference

### Operator parameter behavior (403–409)

These pages complete the instrument begun earlier in the manual. They imply a parameterized, automatable voice architecture; displaying the named controls alone does not implement the synthesis.

- **Global pitch/performance:** Spread allocates two detuned voices per note, panned left/right, with a documented large CPU cost. Global transpose affects already sounding notes. Glide slides from the last note's pitch; in legato operation envelopes are not retriggered. Glide Time does nothing with Glide disabled. A pitch envelope has separate oscillator A–D and LFO destinations, a primary modulation amount and a second destination/amount.
- **Filter:** explicit bypass; 14 types spanning low/high/band-pass and notch with 12/24 dB variants plus Ladder/SVF architectures. Cutoff can receive velocity, key and envelope modulation; resonance means emphasis for LP/HP and bandwidth for band/notch. At 100% key tracking frequency doubles per octave, referenced around C3. A 100% envelope amount can shift roughly nine octaves. The UI alternates between envelope and response. A selectable shaper has Drive and Dry/Wet.
- **LFO:** bypass; ordinary waveforms, sample-and-hold and band-pass noise; band-limited shapes to avoid unwanted clicks. Range Low spans a 50-second period through 30 Hz, Hi spans 8 Hz–12 kHz, Sync follows project tempo. Retrigger resets phase at note-on; disabling it leaves a free-running oscillator. Rate also responds to key tracking; 100% doubles frequency/octave. Attack/intensity follows its envelope. Velocity can modulate overall amount. Separate A–D oscillator destinations, primary amount and secondary destination/amount are required.
- **Four oscillators:** independent bypass; coarse integer frequency ratio and fine fractional ratio; fixed-frequency mode ignores note pitch and combines Frequency with a Multiplier. Output Level controls both audible output and FM depth when used as a modulator. Waveform and envelope display modes; editable 16/32/64 partials. Feedback works when no other oscillator modulates that oscillator. Phase and retrigger/free-run state must be stored. Harmonic Repeat generates progressively fading higher partials; Off truncates above the selected partial count. Velocity can change frequency continuously or in quantized coarse-frequency steps; key and velocity can also alter level.
- **Envelopes:** Initial → Peak over Attack, Peak → Sustain over Decay, then End over Release; note-off starts release from the current level even during attack/decay. Oscillator amplitude attack is linear; decay/release are exponential with release ending at silence. Filter/pitch envelopes expose adjustable attack/decay/release slopes and a selectable end level. Loop retriggers after decay with a transition back toward Initial controlled by Loop Time. Beat/Sync retrigger at specified beat intervals; Sync aligns to song time. Trigger ignores note-off. Velocity affects segment durations, not the fixed Beat/Sync interval. Retriggered envelopes proceed from their current level toward Peak.
- **Context operations:** copy oscillator configuration; set all envelope levels maximum/middle/minimum; constrain partial drawing to odd/even harmonics; normalize oscillator output; export `.ams` waveforms. Play By Key sets cutoff to 466 Hz and tracking to 100%.

Acceptance examples: change transpose while a note rings; compare LFO free-run versus retrigger; release a note halfway through attack; verify velocity does not alter Sync interval; disable unused stages without leaving unintended modulation active. No proprietary oscillator/filter equations are supplied here.

### Orchestral libraries (409–410)

- Libraries install as separate packs and require the original vendor's authorization. The manual's purchase/authorization process is not a BeatMeat dependency.
- Categorized Instrument Rack presets are loaded by dragging to an empty MIDI track.
- Full and Lite both use 24-bit multisamples; Lite reduces layers/zones and resource demands. LE uses 16-bit samples.
- Switching quality variants retains Macro edits.
- Solo and Section presets combine all articulations; individual articulations are also presets. Multi-articulation variants use one chain per articulation and a real-time articulation selector Macro.

BeatMeat must source its own legitimately usable library to offer corresponding material. The PDF does not contain those samples.

### Sampler (411–423)

**Multisample organization/import**

A multisample is a collection of layers captured at different pitches and playing intensities. Loading a preset into an armed MIDI track permits immediate audition. Import can create a Sampler preset or an Instrument Rack containing multiple Samplers where the original structure needs it. The cited legacy formats are not a promise that BeatMeat supports them.

For most imported formats, copy actual samples into the local library so the imported preset survives removal of the original. EXS24/GarageBand and Kontakt imports reference their original WAV/AIF files instead; provide an explicit collect-and-save operation to make them portable. Legacy AKAI CD-ROMs require a separate nonstandard-volume discovery/mounting path. Do not silently treat ordinary file browsing as AKAI support.

**Three intersecting zone filters (414–417)**

Every sample layer has a key zone, velocity zone and sample-selector zone. An arriving MIDI note is eligible only if all three accept it. Key zones use MIDI notes and can span the complete MIDI range; velocity uses 1–127; selector uses 0–127. Layer selection is distinct from audible triggering. Auto Select highlights all layers eligible for a currently held note.

Zones support drag-to-move, edge resize and top-corner fade handles. Crossfades can be linear or constant power. A sample layer's root key determines the natural playback pitch; key range does not itself establish the root. Changing the sample selector after a voice has triggered must **not** swap the sample for that already active voice.

Provide a sortable/descriptively named layer list, per-layer selection linked to the sample display, readable status information, and editor zoom. Hundreds of layers must not require rendering/audio work on the real-time callback.

**Per-sample playback (417–420)**

- Root key; ±50 cent detune; full attenuation to +24 dB level; independent pan.
- Start/end in samples or time; the envelope's attack can make the audible onset later than Sample Start, but Sample End still bounds playback.
- Optional zero-crossing snap uses the left stereo channel, so stereo material may still need a crossfade.
- Reverse is global/modulatable and changes read direction without destructively writing a reversed file.
- Sustain modes: off, forward loop, ping-pong loop. With no sustain loop, play until sample end or envelope completion. With sustain active and release mode off, continue in sustain looping during the amplitude release.
- Link temporarily makes Sample Start equal Loop Start while preserving the original disabled value for restoration.
- Release modes require sustain: off; leave sustain loop and proceed once to Sample End; forward release-loop from Release Loop point to Sample End; ping-pong release-loop. The release envelope bounds all these modes.
- Sustain/release boundaries have separate crossfades and detune controls. Default loop crossfades use constant power; linear is an explicit alternative.
- Interpolation quality and load-entire-multisample-to-RAM are global controls with documented CPU/RAM tradeoffs.

**Modulation/synthesis (420–423)**

Each voice has a dedicated 21-waveform AM/FM oscillator used only for modulation, never directly mixed as audible audio. A multi-stage pitch envelope modulates sample pitch and optionally that oscillator. Its attack/decay/release slopes are editable through diamond handles.

Polyphonic filters include morphing M12/M24/SVF types that continuously cycle LP→BP→HP→notch→LP, plus non-morphing classic 24 dB modes. Cutoff has an envelope. Four shaper curves, Amount and selectable shaper-before-filter or filter-before-shaper ordering are required if this device is implemented.

The global amplitude envelope supports up to 32 simultaneous voices and optional retriggering. A modulation tab provides another loopable envelope and three LFOs, including tempo synchronization. LFOs 2/3 have Phase mode (same rate, channel phase offset) and Spin mode (right channel up to 50% faster). LFO attack, per-note retrigger, initial phase offset and keyboard rate scaling are separate states.

Key, note velocity, release velocity, aftertouch, modulation wheel, foot controller and pitch bend each map to two destinations with independently adjustable depths.

Useful tests: overlapping key/velocity/selector zones; selector changes after note-on; stereo loop clicking; sustaining release inside versus outside a sustain loop; ping-pong boundaries; note-off during envelope attack; voice-limit/retrigger behavior; ordering shaper/filter changes sound; sample references remain valid after collecting.

### Session Drums (424–426)

This is separately licensed acoustic multisample material, organized as Drum Racks. Stereo kits are preprocessed and have Full 24-bit/LE 16-bit variants. Multimic kits provide close/internal microphones, bleed into other microphones and independent ambience returns. At minimum its described routing includes Snare Bottom, Overhead and Room return chains alongside individual instrument channels.

Related-sample alternation on retrigger prevents the machine-gun effect. Macro controls include hi-hat openness (also responding to MIDI CC4) and velocity sensitivity; stereo macros additionally expose drum tune/decay, multimic macros ambience/returns.

Replacing an instrument folder at the pad level replaces all microphone components for that instrument while retaining other pads. Common note mapping across kits makes swapping predictable. Component-level hot-swap filters the browser to matching presets. A packaged clip can load notes, kit and custom effects together. The referenced drum recordings are not in the manual and must not be fabricated as included assets.

### Simpler (427–431)

A sample voice passes through sample-region playback, amplitude/pitch/filter envelopes, filter, LFO and pitch/pan/volume controls. Converting presets between single-sample and full multisample devices should preserve compatible settings; Simpler's sample view is unavailable in its special multisample mode.

- Drag a sample or a Session/Arrangement clip onto the instrument; with a clip, use only its start/end/loop-demarcated source region. Replacement and hot-swap are separate operations.
- Start and Length are percentages of the selected source region. Start=25%, Length=50% produces the middle half ending at 75%.
- With Loop off, play once. With Loop on, the first traversal begins at Start, then repeats the tail region defined by Loop length. Moving source start/end tries to preserve loop length and adjusts related values as needed.
- Zero-crossing snap uses the left stereo channel. Loop Fade adds a constant-power crossfade, with a contextual linear alternative. Waveform zoom is vertical drag; pan is horizontal drag.
- Separate amplitude, filter and pitch ADSRs; independently adjustable filter/pitch envelope amounts.
- 12/24 dB LP/BP/HP and notch filter modes; cutoff/resonance; LFO, velocity, envelope and keyboard cutoff modulation.
- Per-voice LFO has sine, square, triangle, saw-up, saw-down and random shapes, 0.01–30 Hz or tempo divisions. Rate scales with key if enabled, and its intensity can have an attack ramp. Destinations include filter, pitch, pan and volume.
- Monophonic Glide versus polyphonic Portamento; separate slide time. Spread creates detuned hard-left/hard-right voice pairs. Its allocation is determined at note-on, so changing Spread does not retroactively restereo an existing voice.
- C3 plays at natural pitch, global transpose is ±48 semitones, pitch-bend sensitivity is ±5 semitones. Oldest-voice stealing applies beyond the selected voice count; show a visible steal indicator.
- Pan can receive randomness/LFO; volume can receive velocity/LFO. CPU economy comes from disabling unused filter/LFO, selecting cheaper filter slopes, mono source material and reducing polyphony.

### Tension physical-model string instrument (432–446)

The described chain is exciter → string (with damper and finger/fret termination interaction) → optional filter → body, optionally using a pickup. Independent section bypass saves processing. The manual explicitly warns that interdependent settings can make no sound or extremely loud sound. It does not provide the coupled equations, numerical solver or exact proprietary coefficients needed to reproduce the original.

**Exciter:** Bow, Hammer, Bouncing Hammer or Plectrum; the bow has force/friction/velocity, hammers have mass/stiffness/velocity/damping, plectrum adds protrusion. Position is measured termination-to-midpoint (0–50%). Relative position changes with string length; fixed position models a physically stationary picking location. Velocity/key scaling affects relevant parameters. With both exciter and damper off, nothing excites the string.

**String:** Inharmonicity detunes upper partials; damping changes high-frequency content (higher displayed value means less damping/more partials); decay controls ringing; Ratio shortens note-release decay while preserving onset decay.

**Vibrato:** rate, amount, delay, attack and mod-wheel influence. Error adds random deviations across rate, amount, delay and attack.

**Damper:** mass, stiffness, velocity, mechanism damping and contact position, with key/velocity modulation. Gated mode applies at note-off; ungated mode remains in contact and disables velocity behavior. Strong stiffness/mass can change tuning. Above ~50% mechanism damping, bouncing can paradoxically lengthen decay. Excessive contact velocity can produce loud note-release sounds.

**Termination/pickup/body:** finger mass/stiffness and fret stiffness alter effective string termination. Pickup position controls tone. Body type, discrete size, high/low cuts and body decay shape resonance; String/Body crossfades direct string and resonated body. A shared output gain appears on both tabs.

**Filter/global:** 2nd/4th-order LP/BP/notch/HP/formant filters; for formant types, resonance traverses vowel sounds. Cutoff/resonance modulation comes from enabled ADSR/LFO/key sources. ADSR attack may shorten with velocity; sustain can scale with velocity. LFO sine/triangle/rectangular/stepped random/smooth random, delay/attack and Hz/tempo-sync.

**Keyboard:** voice stealing priority High/Low/Last; octave/semitone/coarse and ±50 cent fine tuning; variable bend range. Stretch tuning raises upper and lowers lower notes at positive values, inverse at negative values; Error introduces note-dependent tuning deviation. Unison stacks two/four voices with detune and staggered activation. Portamento has independent enabled, Legato-only and interval-proportional time modes.

### Essential Instrument Collection (446–448)

A separate multi-gigabyte vendor sample collection, not inherent in the app or this PDF. Full/Lite 24-bit versus LE 16-bit follows the orchestral quality pattern, with Macro mappings preserved. The inventory spans acoustic/electric keyboards, solo/ensemble strings/brass/woodwinds, guitars/basses/harp, mallets, choir, drum machine and acoustic kit. Guitar single-key chord banks offer up/down strums; pick bass has up/down strokes in different octaves. BeatMeat should use independently sourced assets and accurate labels, not claim these vendor sample banks are bundled.

## Chapter 24: extensibility / Max for Live (449–450)

The functional blueprint is an extensible device container supporting audio effects, MIDI processors, instruments and controllers, each with presets, an external patch editor and project-managed dependencies. Editing/saving a patch updates all instances referencing that patch in the current set. Patch files can reside in a shared library or a project folder and must participate in collect/manage operations.

A BeatMeat extension format could implement these concepts independently. Installing or embedding Max for Live itself requires its separate runtime and rights; the manual supplies neither. A generic node editor or a blank device named Max is not equivalent functionality.

## Chapter 25: sharing projects (451–454)

- Share is an explicit save/upload command that prompts for a project name and authenticates only if necessary.
- Upload the set plus referenced media absent from the remote store; download only dependencies absent locally. This implies content-addressed/deduplicated media bookkeeping rather than independent blind ZIP uploads.
- Transfers happen in the background; quitting during a transfer offers to resume next launch.
- Before upload, identify non-portable tracks (third-party/add-on devices and hardware-dependent external instrument/effect tracks) and offer a render/freeze route. Groups, returns and master are not freezable in this scheme.
- A transfer browser appears only when the read-only cache contains something; show progress and pause/resume controls, open only completed downloads.
- The cache is evictable and must not serve as permanent project storage. Saving a downloaded project to a normal directory collects its media into a self-contained copy.

No Ableton sharing endpoint/account is available to BeatMeat merely because it is described here. A new backend, authentication, storage/quota policy, resume protocol and user consent would be needed for a corresponding BeatMeat service. Local self-contained project export is a useful first implementation, but should not be labeled cloud collaboration.

## Chapter 26: remote control (455–467)

### MIDI routing and port setup

Mappings address **Session slots**, not the clip currently occupying a slot. Remotely assignable targets include slots, toggles, radio groups, continuous controls and crossfader. Remote-control MIDI is distinct from track-input MIDI: a note consumed by a mapping no longer plays the instrument. Distinct indicators should help diagnose this.

Up to six supported-control-surface entries each select a model and input/output port. Some require an explicit manufacturer-specific preset dump, only after the device is ready. Context-sensitive instant mappings follow selected devices, may be overridden manually and may support locking to a device; instrument locking on track arm is the default for supporting surfaces. Show a hand/lock indicator. Not every surface supports locking.

Manual mappings require a Remote-enable flag per input port. Multiple enabled ports are merged; an output Remote flag enables physical/LED feedback when application values change. Port activity is visible without presuming that every message has a valid target.

### Three absolute-control takeover modes (460)

| Mode | Required behavior |
|---|---|
| None | First movement immediately sets parameter to hardware value, even if discontinuous |
| Pick-Up | Ignore motion until the physical value reaches/crosses the current parameter value; then track 1:1 |
| Value Scaling | Converge smoothly from destination to physical value as hardware moves; track 1:1 once equal |

These states must be re-established when a physical control switches banks/destinations; merely low-pass filtering all incoming values is not the documented behavior.

### Mapping browser and learn flow (461–462)

Show it only during MIDI/Key/Macro map modes. List physical element, target path/name and editable minimum/maximum. Min greater than Max expresses inversion; contextual invert and Delete are explicit commands. Instant/context-sensitive mappings are excluded from this manual mapping list.

Learn: enter highlighted MIDI mode → choose a highlighted destination → receive hardware message → store/display mapping → leave mode. Key learn follows the same flow with keyboard events and a distinct red highlight. Map mode must not trigger normal performance actions while assigning a key.

### Message semantics (462–464)

- Note On/Off reaches Session launch modes (trigger/gate/toggle/repeat as specified elsewhere). For ordinary switches Note On toggles. For radio controls Note On cycles. For a continuous target, a single note toggles Min/Max; a note range produces equally spaced discrete values.
- Chromatic Session triggering learns a root note plus notes below/above as the playable range, retaining the root's original clip transposition.
- Absolute CC: slot ≥64 means note-on, ≤63 note-off; radio targets divide 0–127 among options; continuous targets map 0–127 to min/max. Track/device activators treat values inside Min/Max as on and outside as off; reversed bounds invert this membership. Other toggles use the 64 threshold.
- Pitch bend/14-bit absolute mappings use 0–16383 with midpoint 8191/8192.
- Relative modes are Signed Bit, Signed Bit 2, Binary Offset and Two's Complement; each has a linear variant for internally accelerated encoders. The manual lists increment/decrement ranges but not every magnitude-decoding equation. Signed Bit: 1–64 increment and 65–127 decrement; Signed Bit 2 reverses those signs; Binary Offset: 65–127 increment, 63–1 decrement; Two's Complement: 1–64 increment, 127–65 decrement. Test neutral/boundary values explicitly rather than inferring all behavior from this coarse table.
- Relative increment/decrement triggers Session note-on/off, turns switches on/off and moves radio groups forward/back. Continuous controls change by the interpreted amount. Slow leftward learn gestures help infer encoder format, with a manual override chooser.

### Relative Session and key navigation (465–467)

An assignable strip appears in map mode: highlighted scene up/down, scene-number encoder, launch highlighted scene, and launch each track's slot in that scene. An optional select-next-scene preference advances after launch, and highlighted scenes remain centered in view. Clip-view mappings follow current clip selection and therefore can affect any selected clip; relative encoders avoid abrupt changes when selection changes. Computer-key remote mappings must remain distinct from the computer-as-MIDI-keyboard feature.

## Chapter 27: APC40 (468–478)

This chapter specifies hardware-assisted workflow, not the wire-level message map or a tested hardware driver.

- Setup chooses surface preset and USB MIDI ports. The clip matrix covers **8 tracks × 5 scenes**, with amber occupied, green playing and red recording. Pressing an empty slot in an armed track records; stop buttons exist per track and globally; scenes launch rows.
- An on-screen border identifies the matrix's current window. Plain arrows move one scene/track; Shift moves five scenes/eight tracks.
- Shift-overview maps each physical pad to an 8×5 block, covering 64 tracks ×125 scenes. Row three/column one selects tracks 1–8/scenes 11–15. Shift plus a scene button selects 25-scene blocks. Overview colors mean selected block amber, some clips playing green, no playing clips red, nonexistent area unlit.
- Eight channel strips expose fader, solo/pre-cue, mute and arm; Master fader and separate Cue Level are distinct buses. Bank movement follows the same one/eight-track rules.
- Eight endless encoders follow first device/rack on the selected track, with value-feedback LED rings; four dedicated commands show clip/device view, device bypass and previous/next device. Shift selects among eight banks of eight parameters. Device selection and mapping/feedback updates must remain synchronized.
- Global transport controls play/stop/record; Detail, quantization-none/last-setting, MIDI overdub and metronome each have dedicated functions.
- Track Control encoders select pan or send A/B/C banks; LEDs must track active bank values.
- Tap tempo can also count-in playback (four taps for 4/4); nudge temporarily speeds/slows playback rather than permanently changing the tempo field.
- Crossfader blends A/B track-assignment groups.
- Manual mappings override default surface controls when Remote is enabled; disabling input Remote restores defaults, enabling it restores overrides. Track knobs have four override banks, device knobs eight.

BeatMeat should not mark APC40 support complete without physical I/O/feedback verification and a documented MIDI implementation.

## Chapter 28: synchronization and ReWire (479–484)

### Protocol separation

| Protocol | Timebase semantics | Original product roles |
|---|---|---|
| MIDI Clock | Tempo-dependent ticks plus start/stop/song-position information | Master or slave |
| MIDI Timecode | SMPTE seconds/frames, not musical meter/tempo | Slave only |
| ReWire | Shared sample-clock, transport, position and audio streams between local applications | Master or slave, not both simultaneously |

Per-device Sync enable controls output clock transmission; separate incoming/outgoing indicators indicate traffic. External sync enable appears only once an input source is configured and is a separate explicit transport state. Incoming song positions seek the arrangement; with arrangement loop enabled, wrap the external position into the loop interval.

MTC settings are per device: normal SMPTE rates or auto-detect, and an offset interpreted as arrangement start time. Its display format is independently selectable. MTC cannot convey tempo changes; tempo must be set manually. Per-device positive/negative sync-delay compensation adjusts timebase relative to incoming sync, calibrated by comparing rhythmic transients.

### ReWire constraints

The master owns hardware I/O/mixing; the slave sends audio to the master. Launch master first, slave second; quit in reverse order. Slave MIDI tracks are exposed as MIDI destinations, and audio-producing tracks as audio sources. In slave mode: no direct hardware audio I/O or input; host sample rate/tempo/time signature win; external MIDI sync/output controllers are disabled but MIDI control input still works; cannot nest another ReWire slave under the slave; project tempo/signature automation is ignored.

This is a legacy third-party protocol and requires a real compatible runtime/host. A dropdown named ReWire is not an implementation, and BeatMeat cannot claim compatibility without it. Modern alternatives are separate scope decisions, not identical implementations of the manual.

## Chapter 29: audio-computer resources (485–490)

Real-time audio must finish inside each buffer deadline; missed deadlines create gaps/clicks. A useful audio CPU meter represents callback deadline occupancy, **not total process/system CPU**. Audio gets scheduling priority; nonessential screen updates may slow first. Multicore support spreads tracks/devices/I/O where dependencies permit.

Input/output channel activation is user controlled: unused channels add constant I/O cost but automatically toggling them can audibly disrupt hardware. Idle effects may sleep only after their tails finish; a silent/empty track is not always equivalent to no pending effect work. Stress readiness by playing every track with every device active, not by averaging idle CPU.

### Freeze/Unfreeze/Flatten contract (487–489)

- Freeze renders one audio file per Session clip plus one Arrangement track render, then substitutes those files for real-time device/clip processing. Groups cannot be frozen.
- Hardware External Instrument/Audio Effect tracks freeze in real time with appropriate process options; ordinary offline freeze is fast.
- Unfreeze restores editable original clips/devices. Mixer volume/pan/sends and mixer automation remain editable while frozen, as do clip movement/trim/duplicate/cut/paste/consolidate, Session launches/scenes, recording Session launches to Arrangement and dragging frozen MIDI clips into audio tracks.
- Arrangement effect tails become separate temporary adjacent clips with crosshatching. Moving a source clip should allow moving its tail with it. These temporary tail clips disappear on unfreeze.
- Frozen Session clips contain **exactly two loop cycles**; unlinked envelopes may differ after two cycles. Freeze files begin in temporary recording storage, then move to `Samples/Processed/Freeze` when saving. Unfreezing hardware-dependent tracks immediately discards their frozen files.
- Flatten is a separate destructive-to-editability command replacing original clips/devices with rendered audio; keep an undo path and do not confuse it with freezing.
- Frozen time-based/random effects cannot respond to subsequent edits like the real-time originals; render-state differences must be documented and tested.

Disk overload is separate from CPU load: simultaneous channel count, mono/stereo, streaming and recording all affect throughput. Expose disk starvation/recording gaps. Lowering channel count or choosing RAM playback can reduce disk load, at a RAM cost. Historical drive-RPM advice is not a modern hardware guarantee.

## Chapter 30: audio fact sheet (491–501)

The manual's claims are about the tested Live engine, not automatic claims about BeatMeat. It says its release suite then had 473 automated tests; this count must never be presented as a BeatMeat test count.

### Neutral-operation acceptance blueprint

| Operation | Conditions / required comparison |
|---|---|
| Undithered export | Same sample rate, no non-neutral processing; same/higher target word length nulls to source; lower word length necessarily quantizes |
| Plain playback | Same rate, no transposition/stretching; rendered signal nulls to source before hardware output |
| Unstretched Beats/Tones/Texture/Re-Pitch modes | Clip tempo equals set tempo and no groove; returning tempo to original restores neutral behavior; Complex modes excluded |
| A single sum point | 64-bit accumulation; compare opposite-phase 24-bit white-noise/sine pairs repeated eight times, render32-bit and null |
| External input recording | Destination depth at least converter depth preserves received digital data |
| Internal recording | 32-bit recording preserves internal32-bit signal; recording a lower-depth source at32-bit does not create new fidelity |
| Freeze/Flatten | Render32-bit; compare original render and freeze by cancellation, subject to the explicit freeze-state differences below |
| Effect bypass | Dry audio is identical to input; latency-bearing devices retain delay necessary for compensation |
| Internal routing | Destination equals selected tap point, accounting for whether tap is pre/post-device or mixer |
| Split clip | Sample-accurate, seamless source-position split; looping on/off and warped-but-unstretched variants null against unsplit playback |

Live8 uses 64-bit summation at each mixer input, return, master and rack sum, while processing/storage is32-bit between such points. Therefore cancellation claims at a single sum do not imply an arbitrarily deep graph stays mathematically exact.

Freeze-specific exceptions: arrangement tails extend clips; Session freeze is two cycles; rendered tails stop on transport stop; arrangement automation is rendered but Session freezes snapshot parameters at arrangement1.1.1; freeze plays warped Beats clips; randomized devices become the fixed outcome captured at freeze. Flatten preserves that frozen outcome, not a fresh random/real-time recomputation.

### Explicitly non-neutral operations

- Complex/Complex Pro stretching **even at original tempo**; the manual says they use different technology but does not provide it.
- Sample-rate conversion/transposition, realtime or export. A quality flag changes the implementation and CPU/fidelity tradeoff, not the mathematical fact of resampling.
- Gain/volume automation. Manual states volume curves are evaluated **for every audio sample**, avoiding coarse-rate artifacts.
- Dither: add once when reducing word length; internal gain changes already yield32-bit audio;32-bit intermediate export avoids premature requantization/dither.
- External recording below converter depth; internal recording below32-bit when signal has higher precision.
- Consolidation: creates a new normalized sample at selected project sample rate/depth and adjusts clip gain to retain audible level.
- Clip-edge declicking fades (up to4ms), user fades and crossfades.
- Constant-power sinusoidal panning, with **0dB center and +3dB at extremes** in the described Live implementation. This law should be explicitly tested; silently substituting a different familiar pan law would differ from this reference.
- Groove-modified warped playback at any tempo.

For an objective test suite, start with sine, sine-sweep and noise fixtures at16/24/32-bit, then compare rendered/recorded/routed/split results via null residuals, including block-size variation and floating-point boundaries. State the actual tolerance and precision; don't label a clipping guard, resampler, gain change, pan or fade as bit-neutral.

The manual's recommended quality setup disables stretch/fade/transposition, fixes project rate from the outset and renders32-bit at that rate. This is advice illustrating tradeoffs, not a mandate to remove the user's creative features.

## Chapter 31: MIDI fact sheet (502–509)

### Distinct timing paths

1. **Recording:** timestamp incoming notes/controllers against song time accurately.
2. **Playback:** schedule stored notes/controllers to hardware or software instruments faithfully.
3. **Playthrough:** receive hardware MIDI and render/output it promptly and consistently.

Latency is predictable delay; jitter is varying delay caused by clock conversion, scheduling and separate MIDI/audio/UI paths. The reference prefers consistent latency over jitter. Incoming driver timestamps are used rather than UI receipt time. When monitoring is enabled during recording, an additional audio-buffer-dependent timestamp shift records the time heard through the DAW instead of the time the physical key was played. Disable monitoring when directly listening to a hardware instrument or recording another hardware sequencer, otherwise that compensation is inappropriate.

Outgoing events should use timestamp scheduling supported by the driver. Incoming event capture must continue during audio overload, even when playthrough drops out; later playback of the recording should remain accurately positioned. Input capture and timeline conversion must therefore not be dependent on UI refresh or a successfully completed audio render.

External serial MIDI bandwidth, hardware keyboard-scan rate, driver quality, clock accuracy and chain length remain outside a DAW's complete control. Do not infer a universal timing guarantee from a passing in-process test.

### Measurement blueprint (506–508)

For input timing, split the same electrical MIDI signal to a DAW's MIDI recorder and a zero-latency MIDI-to-audio converter recorded simultaneously as audio. Compare MIDI timeline events with audio pulse positions. For output, play MIDI and a corresponding audio reference into a separate recorder/converter setup. Test multiple interfaces, rates, buffers and realistic CPU load. The manual tested36 configurations around50% CPU; most of its events were within±1ms, but worst cases varied by interface to roughly±11ms. These are historical hardware measurements for Live, not BeatMeat results or acceptance thresholds automatically inherited by it.

Expose buffer size and timestamps clearly, use high-quality/current drivers and support hardware loopback measurements. On macOS a CoreMIDI adapter with host-time↔sample-time conversion and audio-buffer-aware scheduling is an architectural prerequisite; a piano-roll UI or MIDI-file parser alone does not implement these paths.

## Chapter 32: keyboard and contextual command system (510–521)

A command registry should be the shared source of menu items, shortcuts, key mapping and accessibility actions, and should scope editing commands to the focused view. Commands that act on selected loop braces, clips, notes, tracks or envelopes must not silently act on a different target.

| Section / PDF page | Command family and behaviors |
|---|---|
| 32.1 /510 | Fullscreen; Session↔Arrangement; Track↔Clip details; show/hide detail, info, browser, overview, I/O, sends, mixer; preferences |
| 32.2 /511 | Menu keyboard traversal and Return activation; original Windows Alt-menu conventions are platform-specific |
| 32.3 /511 | Increment/decrement; fine dragging; default reset; direct numeric entry; dot/comma advances musical-time fields; Escape cancels and Return commits |
| 32.4 /512 | Browser up/down and folder expansion; set browser root; load/preview; search/focus results; ordinary edit operations also apply in browser |
| 32.5 /512 | Play from start marker/stop; continue from stopped position; play arrangement selection; record; back to arrangement; activate tracks1–8 |
| 32.6 /513 | Cut/copy/paste/duplicate/delete/undo/redo/rename/select-all; variants extend scope across tracks/time or selected envelopes; Tab advances during renaming |
| 32.7 /514 | Loop/start/end operations require marker/brace selection: move/nudge, shift a full loop, double/halve or shorten/lengthen, select material within loop |
| 32.8 /514 | Session launch selected slot; arrow navigation; all-slot selection; copy-drag; add/remove stop button; insert MIDI clip/scene/captured scene; nonadjacent scene movement; browser clips as a scene |
| 32.9 /515 | Arrangement split, consolidate, fades/crossfade, loop selection, insert silence, pan selection, unfold tracks, follow transport |
| 32.10 /516 | Add audio/MIDI/return; rename/next; group/ungroup; expand/collapse; nonadjacent movement; multitrack arm/solo; add browser device |
| 32.11 /516 | Envelope fine dragging and bypass breakpoint grabbing |
| 32.12 /517 | Distinct MIDI-map, key-map and computer-as-MIDI-keyboard toggles |
| 32.13 /517 | Zoom; adjacent/nonadjacent/append selections; follow/autoscroll; pan selection |
| 32.14 /518 | Audio-clip quantize/options; select/move warp marker; follow; region movement with start marker |
| 32.15 /518 | MIDI quantize/options; vertical/horizontal scroll; copy notes; note-editor velocity drag; double-click add/delete; Home/End insertion cursor; follow; region movement |
| 32.16 /519 | Draw; narrower/wider grid; triplets; snapping; adaptive/fixed grid; momentary snapping bypass |
| 32.17 /519 | Global launch quantization:1/16,1/8,1/4,one bar,off |
| 32.18 /520 | New/open/close/save/save-as/quit/hide; audio/video export; MIDI export |
| 32.19 /520 | Plugin windows; multiple windows and Mac keyboard passthrough; group devices; group activation; append devices; load selected browser device |
| 32.20 /521 | Right-click/Ctrl-click context commands; some context options are persistent global preferences, not selection-local edits |

### Visually verified native Mac shortcuts

Verified against rendered PDF pages510,519,520, not just glyph-incomplete text:

- Session/Arrangement **Tab**; Track/Clip **Shift-Tab** (or Control-F12); fullscreen Control-F11.
- Detail **Command-Option-L** (or Control-Shift-F12); Info **?**; Browser **Command-Option-B**; Overview **Command-Option-O**; I/O **Command-Option-I**; Sends **Command-Option-S**; Mixer **Command-Option-M**; Preferences **Command-comma**.
- Draw **Command-B**; narrow/widen/triplet/snap/fixed-vs-adaptive grid **Command-1/2/3/4/5**. Momentary snap bypass is **Command** while dragging on Mac (different from Windows Alt).
- Global quantization **Command-6/7/8/9/0** → sixteenth/eighth/quarter/bar/off.
- New/Open/Close/Save/Quit/Hide **Command-N/O/W/S/Q/H**; Save As **Command-Shift-S**; Export Audio/Video **Command-Shift-R**; Export MIDI **Command-Shift-E**.
- Plugin windows **Command-Option-P**; Shift-click the plugin Edit control opens its Mac-keystroke-aware window. Group/Ungroup devices **Command-G/Command-Shift-G**; Option-click a group activator changes all devices; Shift-click appends devices to selection; browser Return/double-click loads.

Other well-supported text rows include Space transport, F9 record, F10 back-to-arrangement, F1–F8 track activation, Return Session launch and arrows for grid navigation. Before claiming exact keyboard parity for all remaining modifier-heavy rows, inspect their original rendered tables; text extraction alone omits modifier icons.

Context-only commands on521 include create folder, analyze audio, search in folder, close folders, refresh, detailed warp/grid settings and Operator oscillator/envelope copy/paste. Preserve clear local-versus-global effect of these commands and provide Undo where appropriate.

## Index audit (522–534)

The complete index was read. It corroborates rather than expands the main-body feature taxonomy. Its pages cover:

-522 A/analysis/arrangement/Analog;
-523 audio/preferences/automation and clip envelopes;
-524 clips/Collision/controllers;
-525 CPU/cropping/crossfader/cue/devices/delay compensation;
-526 effects/EIC/Electric/envelopes/export/file management;
-527 grid/groove/group/Impulse/import/input/instruments;
-528 library/launch/loop/locators/Live projects/Max/Macros/metronome;
-529 MIDI/monitoring/multisampling/mixer/Operator;
-530 Operator parameters/plugins/presets/pan/preview/quantization;
-531 racks/routing/recording/returns/ReWire;
-532 Sampler/samples/Session/scenes/save;
-533 sync/Simpler/Tension/tempo/transport state;
-534 track/time/transpose/undo/utility/velocity/video.

An index hit is not evidence of implementation or additional source material. In particular, Audio Units/VST hosting, video, MIDI import/export, multichannel routing, compensation, time-signature automation, legacy file formats and authorization each require their actual main-body behavior and an independently verified implementation.

## Priority requirements for the BeatMeat build

1. Make the foundational session/arrangement/transport, clips, audio import/rendering and project persistence real before adding named device placeholders. Provide a visible coverage matrix separating implemented, partial, absent, external and untested features.
2. Adopt a deterministic sample-clock timeline, stable MIDI timestamps and sample-accurate automation. Keep file I/O, decoding, allocation, UI work and controller discovery off the render callback; buffer failures need explicit indicators.
3. Test neutral unity playback, routing, bypass, internal recording, splitting and summing by cancellation. Test fades, panning, resampling and dither with their actual non-neutral behavior rather than broad sound-quality claims.
4. Preserve source data and editable original state for non-destructive clips and freeze; make flatten a separate operation. Save/collect external media so a project survives source-file moves and cache eviction.
5. A playable original sampler/synth is useful, but do not use vendor instrument names or images to imply that their physical models, sample collections or Max runtime were implemented. The source manual is not a package of licensed sounds or proprietary algorithms.
6. MIDI learn, takeover and slot-address mapping are concrete future functionality; a keyboard shortcut is not hardware remote control. Hardware integration, clock sync and APC40 need real devices/test evidence.
7. Treat code signing, app packaging, macOS launch, actual audio-hardware performance and distribution as distinct validation outcomes. No source or portable-DSP test alone establishes deployment or professional DAW readiness.
