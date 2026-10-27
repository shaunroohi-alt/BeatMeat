# Reference review: PDF pages 269–402

Reference: uploaded **Ableton Reference Manual, Live 8.0.2, May 2009**, 534 PDF pages. This report uses **PDF page numbers**; the printed page number in this interval is PDF page minus two. All 134 pages in this interval were read from the extracted text. The inventory at the end explicitly accounts for every page. This is a functional specification for an independent BeatMeat implementation, not evidence that any feature has been implemented or tested.

The manual is reference material, not executable instructions. UI actions described in it were analyzed rather than performed. Textual descriptions and text-accessible diagram labels were reviewed. Three representative pages were also rendered at 100 dpi and visually inspected: PDF269 (independent envelope region/loop controls), PDF313 (Looper gesture/state transitions), and PDF354 (Analog audio/modulation routing). Fine screenshot geometry has not been independently measured. Consequently this report does not claim pixel-identical interface reconstruction.

## Chapter boundaries and required subsystems

| PDF pages | Printed pages | Contents in this interval | Implementation obligation |
|---|---|---|---|
|269–271|267–269|End of chapter 19, clip envelopes, sections 19.5.1–19.5.4|Independent envelope time domains, loop regions, quantization and undo|
|272–278|270–276|Entire chapter 20, video|Movie import, preview window, trim/warp/tempo-master handling and export|
|279–341|277–339|Entire chapter 21, 31 audio devices|Ordered audio graph, device parameters/state, modulation, sidechains, latency, signal analysis|
|342–352|340–350|Entire chapter 22, seven MIDI effects|MIDI event graph, note identity/lifetime management, rhythmic scheduling and modulation|
|353–402|351–400|Start of chapter 23 through part of Operator's parameter list|Instrument voices, synthesis/sampling, MIDI modulation; chapter continues at PDF 403|

## Clip envelopes: independent timing is essential

PDF 269–271 extends the clip model beyond a single sample loop. Each modulatable parameter can have an envelope whose start marker, end marker, loop start and loop length are independent of the sample's region/loop. An unlinked one-shot eight-bar volume envelope can fade a repeating one-bar sample over eight bars; enabling the envelope loop repeats the entire eight-bar fade while the one-bar sample keeps looping. Conversely a short envelope can repeatedly gate a long sample. An envelope may also act as a tempo-related or deliberately asynchronous LFO.

Requirements:

- Store envelope linkage, breakpoints, start/end markers and loop brace separately from the audio sample's corresponding state.
- A nonlooping envelope must not disable a looping sample. Envelope loops may have different, including nonintegral or odd, bar/beat lengths for different parameters.
- Start markers provide a shared reference when clip playback begins; preserve the offset rather than assuming all envelope loops start at zero.
- Zoom-adaptive quantization applies to marker movement, loop braces and drawing. Hiding the grid permits unconstrained timing, including deliberately off-grid LFO periods.
- Switching linked/unlinked mode modifies envelope data in the referenced application; switching twice is not a harmless view toggle. Any such destructive transformation must be represented in undo history.
- Acceptance examples: one-bar sample plus eight-bar fade; eight-bar repeated fade; one-bar rhythmic volume gate over a multi-minute source; independent 3.2.1-style envelope period.

## Video scoring: chapter 20

PDF 272–278 specifies QuickTime `.mov` import through the media browser and drag/drop. Arrangement clips retain a movie component and display a distinguishing film-strip title treatment. Session movie import acts as audio-only playback. Embedded QuickTime markers are read from the original file and displayed in the Arrangement/Clip views; they are neither editable nor stored as project-owned markers.

- Trim left/right edges non-destructively. Consolidate, Reverse and Crop replace the internal movie clip with audio-only material; the original movie file remains unchanged.
- Movie preview is a movable/resizable floating window above the main application. Window geometry is application-level state, not per-project. Double-click switches full screen (including another monitor); modified double-click restores the original movie dimensions.
- Movies can contain partial audio/video tracks. Missing video must produce black frames; missing audio must produce silence.
- Scoring defaults make warped video an Arrangement tempo-master candidate and audio clips tempo slaves. Warp must be enabled before the video can be a tempo master. When multiple candidates overlap, the bottommost currently playing candidate wins. Nonwinning video can itself be warped; preview timing must follow that resolved state.
- Dragging a video's warp marker updates preview to the corresponding frame. Embedded markers are useful visual references, not editable warp markers themselves.
- Render/export combines the edited movie and audio mix. The export duration follows the Arrangement selection; selecting the restored original movie duration includes pre-roll.
- Pre-roll workflow: align the first action with song origin by advancing the source start marker; later shift the entire musical composition right and reveal the original movie's earlier frames before final export. Source offset and Arrangement position must be independent values.
- Required tests include partial-track gaps, overlapping tempo masters, frame display during warp edits, internally audio-only transformations, and pre-roll restoration without source mutation.

## Audio-device graph and shared contracts

The audio devices below belong in serially ordered track/rack graphs and on return/master tracks. Device bypass, preset/state persistence, parameter automation, readable parameter units/ranges, sidechain routing, and latency reporting are shared infrastructure rather than separate ad hoc UI controls. Time controls that synchronize to tempo need explicit beat-division state; a number displayed in sixteenth notes is not milliseconds. High-quality modes trade CPU for processing quality and must be serialized. Audible quality or compatibility claims require measurements beyond the descriptive manual.

For sidechains, retain the audible main signal and the detector/control signal as separate routes. Sidechain input gain must not become audible program gain. Detector dry/wet blends the detector sources. Sidechain audition is a deliberately separate monitoring mode. External hardware round trips require explicit latency, with samples retaining sample count across rate changes and milliseconds retaining duration.

### Complete chapter 21 device inventory

| Section / PDF pages | Device | Functional blueprint and edge cases |
|---|---|---|
|21.1 / 279–281|Auto Filter|Low/high/band-pass and notch modes; frequency/Q XY editor plus numerical entry. Envelope follower with amount/attack/release, optional external sidechain gain/blend, plus stereo LFO. LFO rate is Hz or tempo-synced; sine/square/triangle/saws/sample-and-hold. Beat-quantized modulation updates in sixteenth-note units. Phase relates equal-speed channel LFOs; Spin detunes their rates. Mono/stereo sample-and-hold modes replace the phase/spin semantics. Detector signal is not audible output.|
|21.2 / 281–282|Auto Pan|Independent left/right amplitude LFOs create pan, tremolo or chopping. Sine/triangle/down-saw/random; waveform shaping and inversion; Hz/sync rate; stereo phase and common offset; overall amount. Phase zero and 180 degrees must yield different stereo/amplitude behavior.|
|21.3 / 282–284|Beat Repeat|Capture/repeat scheduler with Interval 1/32–4 bars, Offset, Chance, Gate and slice Grid. Manual Repeat overrides the automatic capture conditions. No Triplets restricts division choices. Variation can run per trigger, quarter/eighth/sixteenth or every repeat. Downward resampling pitch shift changes slice duration; Pitch Decay descends over successive repeats. Band filtering, output level and repeat decay. Mix adds repeats, Insert suppresses dry only during repeats, Gate outputs repeats only. Chance zero/one and manual override require deterministic tests.|
|21.4 / 284–285|Chorus|Two parallel delay lines, per-line times, first-line high-pass, second-line Off/Fixed/Modulated modes. Link aligns both delays to first-line time. Modulation amount/rate XY and numeric controls, ×20 rate option, feedback with selectable polarity, dry/wet and Crisp quality mode. Fixed mode does not mean delay two is muted; only its modulation is disabled.|
|21.5 / 285–290|Compressor|Threshold, ratio, knee transfer graph, gain-reduction/output meters, output/makeup, attack/release and lookahead 0/1/10 ms. Detector modes Peak, RMS and nonlinear-release Opto; models FF1/FF2 feed-forward and FB feedback. FB disables lookahead and external sidechain. External sidechain disables automatic makeup. Sidechain offers routing taps, detector gain/blend, detector EQ and listen. Examples cover voiceover/music ducking and kick-driven bass/master ducking; a detector low-pass can isolate kick energy from a full drum mix.|
|21.6 / 291–294|Corpus|Two-channel physical resonator with seven model types: beam, marimba, string, membrane, plate, pipe, tube. Optional MIDI sidechain sets frequency and/or note-off damping; last/lowest-note priority, transpose/fine and pitch-bend range. Free-Hz or synced stereo LFO; phase in sync mode, spin in Hz mode, noise modes ignore both. Resonator spread, quality, damping/material/radius, decay, aspect ratio, brightness, inharmonicity, pipe opening, listening positions and excitation position have model-dependent availability. Band filter, stereo width, excitation bleed, output, input-dependent dry/wet and internal overload limiter. Lowering dry/wet stops new excitation but must not truncate an existing resonance.|
|21.7 / 295–296|Dynamic Tube|Three nonlinear tube characters, drive, bias, spectral tone and output. Envelope amount can modulate bias positively or negatively; attack/release are inactive when amount is zero. High-quality processing reduces aliasing at extra CPU cost. The prose gives character descriptions, not equations for tube models A/B/C.|
|21.8 / 296–297|EQ Eight|Up to eight independently enabled parametric bands per input channel, Stereo/LR/MS modes, two visible curves with one active channel. Low cut/shelf, bell, notch, high shelf/cut. XY edit frequency/gain, alternate-drag Q; cutoff/notch modes have no adjustable gain and vertical movement controls Q instead. Numeric edits, global output gain, gain Scale affecting gain-capable bands only, high-quality mode and historical EQ Four compatibility.|
|21.9 / 298–299|EQ Three|Three crossover-defined bands with −∞ to +6 dB levels, independent kills and signal LEDs even for killed bands (−24 dB threshold). Low/high crossover frequencies, 24/48 dB slopes. 48 dB behavior intentionally colors nominally flat settings; exact response cannot be derived from this description.|
|21.10 / 299|Erosion|Short delay modulated by sine or band-limited noise. XY controls center frequency/amount, modified drag adjusts bandwidth. Sine disables bandwidth. Mono Noise uses a shared generator; Wide Noise uses independent channel noise.|
|21.11 / 300–301|External Audio Effect|Hardware insert: selected audio outputs and return inputs, send/return gain and peak holds, return polarity inversion, dry/wet, manual round-trip latency in samples or ms. Available channels come from audio preferences. Global delay-compensation off disables the latency control. Keep external-send monitoring feedback under control.|
|21.12 / 301–302|Filter Delay|Three parallel delays fed respectively from L, L+R and R. Each has independently enabled input/feedback band filter, time/sync subdivision, fractional beat-time offset, feedback, level (up to +12 dB) and pan. Dry level is separate. Feedback passes through its filter and can become unstable at extremes.|
|21.13 / 303–304|Flanger|Two parallel modulated delays, base delay/feedback XY, feedback polarity, envelope amount/attack/release, stereo six-shape LFO with Hz/sync, phase/spin, delayed-signal high-pass, dry/wet and high-quality mode. Negative envelope amount inverts modulation direction.|
|21.14 / 304–306|Frequency Shifter|True additive frequency translation in Hz, distinct from ratio-based pitch shift. Coarse/fine and stereo Spread/Wide; Ring mode produces sum/difference sidebands and allows post-mix Drive distortion. Stereo LFO modulation has standard six shapes and Hz/sync/phase/spin; random ignores phase/spin. In driven Ring mode, zero Mix can still produce pure distortion because Drive is post-mix. Examples: small drum retuning, sub-2-Hz phasing with dry/wet mixture, sub-20-Hz ring tremolo, spectral inspection.|
|21.15 / 307–308|Gate|Threshold-open gate with indicator, adjustable closed attenuation, Flip inversion, attack/hold/release and approximately 3 dB hysteresis. Sidechain routing/gain/detector blend; external source only triggers the main signal. A closed attenuation of zero dB has no audible attenuation. Tests should cover threshold chatter, hold retriggering and flipped behavior.|
|21.16 / 308–310|Grain Delay|Grain slicing with independent pitch and delayed output. Beat/ms delay plus fractional sync offset, feedback, pitch, per-grain random pitch, Spray time randomization, grain frequency and dry/wet; choose arbitrary XY parameter assignments. Pitch/spray depend strongly on grain duration. High feedback can run away.|
|21.17 / 310–311|Limiter|Input gain, absolute ceiling, stereo-linked versus independent L/R gain reduction, lookahead selection, release/automatic release and reduction meter. Linked mode preserves stereo relationships by attenuating both sides for either peak; dual-mono changes stereo image. Guarantee is invalidated by later gain devices or a master fader above unity. No exact internal limiter algorithm or true-peak conformance vectors are supplied.|
|21.18 / 311–316|Looper|Stateful recording/play/overdub/stop effect; detailed transport, length, tempo, monitoring, undo, reverse, speed, export and feedback requirements are below. Must not be represented as a simple delay line with identical controls.|
|21.19 / 316–321|Multiband Dynamics|Up to three bands with configurable crossovers, per-band active/solo, pre/post gains, upper/lower thresholds and independent ratios. Supports upward/downward compression and upward/downward expansion simultaneously; six regions across three bands. Attack/release apply with opposite threshold-crossing directions for below versus above regions. Soft knee, RMS/peak, global time scaling, Amount scaling ratios toward unity and global gain. Turning off low/high creates a true single-band middle processor.|
|21.20 / 322|Overdrive|Pre-distortion band-pass with XY frequency/width, Drive, post-distortion Tone, compression-related Dynamics and dry/wet. Zero Drive still introduces distortion. Exact proprietary transfer curve is unspecified.|
|21.21 / 323–324|Phaser|All-pass stages with adjustable pole count, frequency/feedback XY, Earth/Space spacing modes and Color; envelope modulation with signed amount, stereo LFO shapes/rate/sync/phase/spin, dry/wet. Feedback turns notches into peaks; nonlinear details need independent design.|
|21.22 / 324–325|Ping Pong Delay|One tapped, filtered feedback delay: first left echo after one delay interval, first right echo after two, right output feeds feedback. Tempo/ms time, bandwidth/frequency filter, feedback, freeze and dry/wet. Freeze stops new input and cycles existing buffer. Delay-time transitions distinguish repitch, crossfade (default) and immediate jump (historical compatibility).|
|21.23 / 326–327|Redux|Independent sample-rate and amplitude reduction. Downsample 1 bypasses temporal reduction; 2 updates every second sample. Soft interpolated reduction extends to 20 samples, hard stepping to 200. Bit depth maps quantization levels; one bit is bipolar, eight bits 256 levels. Overload clipping and LED are defined relative to 0 dB input. Bit reduction can be disabled independently.|
|21.24 / 327–328|Resonators|Five resonators in parallel, input mode/filter, root note/fine and decay, constant-decay option, A/B resonance character and Color. Root feeds both sides, resonators II/IV left and III/V right; independent enable/gain and relative ±24-semitone detune. Disabling root resonator does not disable others. Wet width does not affect dry signal.|
|21.25 / 328–330|Reverb|Independent input low/high cuts, predelay, early-reflection Shape/Spin, room Size, quality, stereo image, late diffusion decay, high/low decay shelves, Freeze/Cut/Flat, Echo Density/Scale, late Chorus, reflection/diffuse levels and dry/wet. Predelay distinguishes onset from decay. Freeze holds diffusion; Cut gates new input; Flat bypasses frequency-dependent decay while frozen. Exact reflection topology is absent.|
|21.26 / 331–332|Saturator|Drive/transfer visualization, six preset shapers plus custom shaper with Drive/Lin/Curve/Damp/Depth/Period. Input DC removal, low-frequency Base and higher-frequency Color EQ, output level, optional final soft clip, dry/wet and high-quality processing. Custom-shaper Drive zero disables custom-shaper influence. Nominal names do not specify exact transfer equations.|
|21.27 / 333–334|Simple Delay|Independent left/right feedback delays with beat/ms time, feedback and dry/wet. No cross-channel feedback. Delay transition modes repitch/crossfade/jump; default crossfade, historical Sets use jump.|
|21.28 / 334–335|Spectrum|Analysis-only device, never modifies audio. FFT block size, analysis channels, refresh cadence, block averaging, line/bins visualization, linear/log/semitone axes, hover frequency/dB/note and peak hold until transport restart. Automatic range disables manual range/zoom; detachable expanded display. Analysis belongs off the realtime render thread.|
|21.29 / 336|Utility|In-chain mute distinct from final track mute, ±35 dB gain, left/right/stereo channel selection, pan, width and independent polarity. Left/right selection duplicates that source to both outputs and disables width. Width zero is mono, 100% stereo, 200% difference-only. A mute before reverb/delay preserves existing tails, unlike a final track mute.|
|21.30 / 337–338|Vinyl Distortion|Tracing model produces even harmonics; Pinch produces odd harmonics with optional opposite stereo polarity. Per-model drive/frequency/Q XY, overall drive, soft/hard vinyl characters and independent crackle density/level. These are model descriptions, not supplied coefficients or recordings.|
|21.31 / 338–341|Vocoder|Separate modulator and carrier filterbanks; carrier may be generated noise, external route, self-modulator or pitch-tracking oscillator. Band count/range/width, per-band attenuation, precise/retro responses, band gate, depth, attack/release, gain, formant shift and dry/wet. Noise carrier has density/downsample shaping. External-carrier normalization Enhance, unvoiced noise/sensitivity/fast-slow, pitch tracking limits/waveform/tuning and mono/stereo/LR variants. Pitch tracker holds last detected pitch and can behave unpredictably on polyphony; preserve state resets explicitly.|

### Looper's transport state machine

PDF 311–316 requires the following distinct states and transitions:

- **Empty → Record:** recording replaces prior material. Finishing a recording can enter Play or Overdub; fixed-length recording selects its destination state.
- **Play → Overdub → Play:** overdubs accumulate over the original loop length. Stop halts playback. Undo removes everything since the latest entry into Overdub, preserving the original pass and older overdubs; Redo restores the removed pass.
- **Clear:** while overdubbing with global transport running, clear the buffer but preserve tempo/length. In other states reset tempo/length as well.
- Global transport running makes Looper commands subject to launch quantization. With global transport stopped commands are immediate.
- Multi-purpose control: empty single-click records; recording/overdubbing/stopped single-click plays; playing single-click overdubs; double-click stops; two-second hold while playing invokes undo/redo; hold while stopped clears. Store enough gesture and current-state information to disambiguate these commands.
- Tempo modes are independent, follow-song, or set-and-follow. Free recording infers tempo after completion; predeclared bars constrain inference. Existing global transport changes how fixed-length recording is scheduled.
- Global transport coupling modes are none, start-only, or start-and-stop; local stop in start-only must not stop the whole song.
- Double buffer length by duplicating material; halve it by keeping the currently playing half. Persist resulting length/tempo.
- Drag export creates a new audio clip, defaulting to repitch warp behavior; import replaces the buffer and can become the basis for more overdubs.
- Playback speed changes pitch and speed together; octave shortcut buttons and Reverse obey launch quantization. Overdubs made during reverse are stored so changing direction later reverses those overdubs relative to the original pass.
- Feedback applies only in Overdub and changes take effect at the next repetition. It is irrelevant in Play.
- Input monitoring modes: Always, Never, Record/Overdub, and Record/Overdub/Stop. Each must be tested in all transport states to avoid duplicate monitoring or unwanted silence.
- Looper exposes an internal insert routing point for feedback through other tracks' devices. This is an explicit cyclic routing case; a graph implementation must model intentional one-buffer or sample delays, not recurse indefinitely.

### Cross-device acceptance cases

1. A sidechain source muted from the master can still drive compression/gating/filter envelopes without leaking audibly into the target.
2. Compressor ratio one is a unity transfer before output gain; verify knee limits and disable incompatible controls in feedback/external-sidechain configurations.
3. Filter/EQ bands disabled for CPU savings retain parameter state; on/off status is distinct from zero gain.
4. Delay-time modulation reproduces each selected transition policy and stereo feedback topology. Frozen buffer state is not equivalent to muting output.
5. Multiband Amount zero yields unity ratios while input/output gains still work; below-region and above-region timing have opposite threshold-crossing logic.
6. Utility-before-reverb mute allows decay tails, while final track mute silences them.
7. A final limiter cannot guarantee the mix ceiling if later gain stages exist; output test must measure the actual final output.
8. Device latency must flow into compensation for the complete graph, including hardware inserts; switching samples/ms units must preserve the documented invariant.

## MIDI effects: chapter 22

MIDI effects transform events before an instrument, rather than processing audio after it. Correct note-off correspondence is part of every transformation: a transposed, repeated, gated or randomized note must eventually release the pitch actually emitted, including when controls change while notes are held. The manual's no-duplicate-pitch rule also requires explicit collision handling.

| Section / PDF pages | Device | Functional blueprint and edge cases |
|---|---|---|
|22.1 / 342–346|Arpeggiator|Arpeggiates held input notes or repeats the chord. Ordered styles include ascending, descending, alternating, converge/diverge, thumb/pinky and input-play-order; Random, Random Other (no repeats until pool exhausted), Random Once (stable until input changes). Rate uses ms or beat sync; gate is percentage of rate and can exceed 100% for overlap. Groove pool changes timing/velocity. Hold persists after releases; held original keys permit adding/removing notes by playing them. Offset rotates the note sequence. Repeats finite/infinite; retrigger off/note/beat with song-aligned scheduling. Transpose applies major/minor scale steps or semitone shifts with signed distance and number of steps. Velocity target/decay and its optional retrigger are separate state.|
|22.2 / 346–347|Chord|Original plus six signed ±36-semitone offsets, each with 1–200% relative velocity. Duplicate pitches are suppressed; duplicate shift controls are shown disabled. Slot order does not change the chord.|
|22.3 / 347–348|Note Length|Trigger from note-on or note-off, fixed ms or tempo-related length, gate scales duration up to 200%. Note-off triggering delays onset until original release and uses on/off velocity balance plus a velocity decay from original note-on. Key scaling changes output duration around C3; negative scaling reverses direction.|
|22.4 / 348|Pitch|±128-semitone transposition with Lowest/Range note filter applied **before** transposition. Out-of-range input is blocked, not passed through.|
|22.5 / 349–350|Random|Chance controls alteration; Choices 1–24 and integer Scale define allowed offsets; Sign selects up/down/both. Random mode chooses offsets; Alt mode cycles a stable series. At Chance zero emit original. Alt at full chance cycles including the initial original pitch as documented, unlike an assumed always-offset algorithm. Scale can constrain randomized notes downstream.|
|22.6 / 350–351|Scale|12×12 input-to-output pitch-class map with movable base. Each input class maps to an output or is removed. Lowest/Range bounds where mapping applies; outside this range notes pass through unmodified, unlike Pitch's rejection behavior.|
|22.7 / 351–352|Velocity|Maps note-on, note-off or both; input low/range and output low/high define curve. Clip clamps, Gate removes out-of-range notes, Fixed emits constant Out High. Random widens output distribution. Drive and Compand shape distribution: positive compand pushes toward extremes, negative toward middle. Preserve legal MIDI ranges and note-on velocity-zero conventions.|

MIDI acceptance priorities: deterministic random seed for regression; off/on symmetry; note-offs after Hold/panic/transport stop; collision handling for Chord and Scale; pretransposition range versus scale passthrough difference; beat retrigger aligned with global song time while ordinary free-rate patterns need not be quantized.

## Instruments: chapter 23, first part

### Analog: PDF 353–364

Architecture is two modeled oscillators plus filtered noise, routable independently into two multimode filters and then two amplitude/pan stages. Filter 1 can feed Filter 2; paths may be serial or parallel. Two LFOs plus four ADSR generators modulate oscillators, filters and amplifiers. Global voice management, vibrato and glide sit above these sections. A device editor has a stable overview and a section-specific detail display; all state still belongs to one instrument.

- Oscillators: independent enable/level; continuously split routing to F1/F2; sine/saw/rectangle/noise; pulse width and LFO pulse-width modulation when supported; octave/semitone/cent tuning. Key scaling defaults to equal temperament and pivots at C3. Pitch-envelope initial/time and LFO depth are independent.
- Sub mode adds an octave-down square or sine based on main waveform, and is unavailable for noise. Sync instead uses an internal reset oscillator whose relative frequency changes timbre.
- Noise has independent output/filter routing and a −6 dB/octave low-pass color filter.
- Filters: second/fourth-order LP/BP/notch/HP/formant options, cutoff/resonance, signed LFO/key/envelope modulation. Filter 1-to-2 amount and Filter 2 slave cutoff offset must remain distinct controls. Slave responds to modulation of Filter 1. Symmetric and asymmetric drive variants are post-filter.
- Amplifiers: independent enable/level/pan and LFO/key/envelope modulations.
- Each filter/amplifier envelope has attack, decay, sustain, release, sustain-time decay, velocity-to-level, velocity-to-attack and linear/exponential segments. Legato reuses the active envelope. Free bypasses held sustain. Loop modes Off, AD-R, ADR-R and ADS-R have different retrigger/release behaviors; Free plus looping can sustain indefinitely.
- LFOs: Hz/sync, sine/triangle/rectangle/stepped or smooth noise. Width changes triangle/rectangle symmetry, not sine/noise. Delay and intensity ramp, phase offset and note retrigger/free-run.
- Globals: volume; dedicated pitch vibrato with rate/delay/attack/random voice deviations/mod-wheel amount; two/four-voice unison with detune/stagger; glide constant-time or interval-proportional and optional legato-only; polyphony and high/low/last note priority; coarse/fine overall tuning, pitch-bend range, stretch tuning and random tuning error.
- Four routing presets change only route/control enabling, not oscillator waveforms, tuning or level. One preset is serial, two are parallel variants, one disables the second filter/amplifier path.
- Physical modeling equations and alias-control design are not provided. An independent subtractive synthesizer can satisfy basic workflow but must not be described as this exact modeled instrument.

### Collision: PDF 365–376

Mallet and noise excitation feed two stereo resonators. UI tabs divide Excitator, Resonators, linked resonator editing, LFO and MIDI; output/polyphony/topology are global.

- Mallet controls level, impact-noise mix/color and stiffness; pitch/velocity can modulate level, noise and stiffness. Noise excitation has level, multimode filter with cutoff/resonance/bandwidth, pitch/velocity/envelope routing and ADSR.
- Both excitators off means silence. Both resonators off also means silence. Disable unused synthesis sections to save CPU.
- Each resonator has semitone/fine tuning, signed note tracking and initial/time/velocity pitch envelope. Model choices are beam, marimba, string, membrane, plate, pipe and tube.
- Parameters include quality/partial count, internal decay, note-off decay, material-dependent damping, pipe/tube radius, membrane/plate aspect ratio, brightness, inharmonicity, pipe opening, listening positions and hit position/randomization. Model selection changes which parameters are meaningful; do not show unsupported knobs as active.
- Per-resonator output level/pan/key-to-pan and original-excitation bleed. Copy applies the physical-properties subsection to the other resonator, not the entire instrument. Linked editing retains differing ranges until dragged to an extreme, when values converge.
- Two LFOs, each with two destinations, signed amounts, depth, key-to-rate and velocity-to-depth; phase/retrigger and Hz/sync. Pitch bend, modulation wheel and aftertouch each route to two destinations, with pitch bend additionally hardwired to pitch.
- Series topology sends excitators into Resonator 1, then mono-sums that result into Resonator 2 while retaining Resonator 1's stereo mixer output. Resonator 1 must therefore be active. Parallel sends excitation directly to both.
- Internal overload limiter, global gain, voice count and same-note retrigger policy. Long decays and modeled resonance can produce very high levels and CPU load; both need testing.
- **Source ambiguity:** Corpus describes Tube as open at both ends (PDF 293); Collision describes Tube as closed at both ends (PDF 370). Do not silently treat this inconsistent prose as an exact physical blueprint.

### Drum Machines: PDF 376–377

This is a separately licensed, multisampled drum-computer library packaged as Drum Rack presets and associated MIDI clips, with macros and browser organization. The PDF contains no corresponding samples. BeatMeat may provide an independent drum rack/sample-import workflow and original sounds, but cannot truthfully claim this exact content is included.

### Electric: PDF 377–381

Modeled electric piano: hammer/mallet strikes a tine/tone fork, with mechanical damper noises and nonlinear magnetic/electrostatic pickup output. No sample or wavetable content is supplied by the manual.

- Mallet stiffness and force with velocity/key scaling, impact-noise frequency/decay/level and key-dependent noise level.
- Fork has separate tine and tone-bar decay/level, tine harmonic color and key-to-tine level; shared post-release decay.
- Damper hardness/tone and gain, with continuous attack-versus-release noise blend.
- Pickup R/W modes, input drive versus output compensation, key-to-output level, symmetry and distance. Moving pickup closer raises distortion; same final volume can have different timbre depending on drive/output balance.
- Global gain/polyphony, semitone/fine tuning, stretch tuning and pitch-bend range. Exact physical equations are absent.

### External Instrument: PDF 381–383

A routing device, not a sound generator: MIDI output to a physical port/channel, ReWire slave/device or another multitimbral plug-in/channel; audio return from hardware inputs, ReWire channels or plug-in auxiliary outputs; return gain and manual latency. Internal plug-in main audio remains on its owning track. Dynamic channel choices depend on audio/MIDI configuration. Latency units preserve samples or duration as described for hardware audio inserts; internal routes compensate automatically and disable the manual latency slider. Global compensation off disables it. ReWire is a historical integration requirement, not a native macOS audio framework.

### Impulse: PDF 383–386

Eight-slot drum sampler with C3–C4 trigger mapping and editor row labels; independent sample load/hot-swap/delete, audition, mute and solo. Slot labels appear in folded MIDI view even without notes. Pitch/Scale MIDI effects can remap triggers.

- Per-slot values are captured at note-on, not continuously applied to already sounding voices. This applies to automation and clip envelopes too.
- Last two slots can mutually choke each other for open/closed hi-hat behavior.
- Start offset up to 100 ms, tune ±48 semitones with velocity/random modulation; stretch −100…100% with two material-dependent algorithms and velocity modulation.
- Filter type/cutoff/resonance with velocity/random frequency modulation; optional saturation and compensated slot volume.
- Decay up to 60 s; Trigger starts decay with note while Gate delays decay until note-off. Pan supports velocity/random modulation, level supports velocity.
- Global level, transposition and Time scaling for stretch/decay. Individual slot outputs must be routable to other tracks, not merely collapsed into one stereo bus.
- The two stretch algorithms and saturation coefficients are not specified.

### Latin Percussion: PDF 386–388

Separately licensed acoustic, multi-articulation drum/percussion samples and MIDI sets, presented as Drum Rack kits and instrument groups with tuning/room/envelope macros. Groups can be swapped without replacing other pads. No sound recordings are embedded as executable assets in the PDF. Independent rack organization and original/imported samples can reproduce the workflow but not claim the same library.

### Operator: PDF 388–402, continues beyond this review interval

Hybrid FM, subtractive and additive synthesis. Four oscillators can be carriers, modulators or both using eleven selectable connection algorithms. Each oscillator has its own envelope; there are also filter, LFO and pitch envelopes (seven total), plus a filter, modulation routing and globals. The algorithm itself can be automated/modulated.

- Built-ins include sine, reduced-bit sine, harmonic-limited saw/square/triangle, digital saw/square, looped noise and white noise. User additive editing exposes 16/32/64 partials, repetition with high-frequency rolloff, even/odd/all edits, optional normalization, copy/paste between oscillators and `.ams` waveform import/export.
- Coarse/fine ratio tuning or fixed Hz/multiplier (down to 0.1 Hz), velocity-to-frequency with optional integer quantization, gain and envelope velocity/key tracking, phase and note retrigger/free-running. A nonmodulated oscillator may feed back into itself; feedback should not be applied indiscriminately to all oscillators in a graph.
- Aliasing controls include interpolation, antialias mode and Tone. Complex FM can generate high partials even from simple oscillators. Manual quality descriptions are not a full algorithm specification.
- LFO runs through audio rates, with classic/S&H/filtered-noise waveforms, low/high/sync range, key-to-rate, phase/retrigger, overall amount, own envelope and velocity-to-amount. Destination A selects oscillator/filter targets; an independently scaled B targets another parameter.
- Oscillator envelopes have three transition rates and three levels; filter/pitch envelopes also have adjustable segment slopes. Breakpoints retain selection for keyboard adjustment. Copy/paste of envelope shapes is supported.
- Loop mode restarts after sustain with an explicit loop time. Beat mode repeats in song-time fractions without quantizing note-on timing. Sync mode quantizes the first repetition to a sixteenth when transport runs; when stopped it behaves like Beat. Retrigger from the envelope's current level avoids a click.
- Trigger envelopes ignore note-off. Global Time scales envelope rates but not beat/sync repeat times. Global key scaling and per-envelope velocity scaling add independent timing modulation. Pitch envelope can target any oscillators/LFO plus another parameter; filter/pitch envelopes have explicit post-note-off End level.
- Fourteen filter types include 12/24 dB variants, self-oscillating state-variable modes and ladder variants, cutoff/resonance, key/velocity/LFO/envelope modulation, followed by selectable waveshaping/drive/mix. Shaper mix zero bypasses that processing.
- Globals cover polyphony/oldest-voice stealing, same-note retrigger, mono legato when voice count is one, level/pan, key/random pan, internal velocity/key/aftertouch/bend/mod-wheel maps with two destinations each. Fixed pitch-bend and global envelope-time-to-key functions coexist with assignable modulation.
- Polyphonic glide starts a note at the last pitch; spread uses two detuned left/right voices and is sampled at note-on, so later control movement need not affect an already sounding voice. Global transpose is separate.
- CPU savings include disabling unused filter/LFO, reducing polyphony/spread and disabling interpolation/antialias. Turning oscillator enable off is explicitly not guaranteed to save CPU.
- PDF 400–402 begins the exhaustive parameter list. It covers global controls, modulation destinations (oscillator levels/crossfades/feedback, FM drive, filter frequency/Q/envelope, shaper drive, LFO rate/amount, pitch envelope amount, global volume/pan/tone/time), then pitch-envelope enable/amount. The rest belongs to the next report; do not mark the full instrument parameter list covered by this interval alone.

## What this manual does not supply

The descriptions define externally visible behavior, signal-flow organization, parameter meaning, state transitions and examples. They do not provide source code, numerical coefficients for proprietary models, sound-library audio, anti-alias filter designs, time-stretch implementations, model-identification data, historical preset files or compatible file-format specifications. Exact sound/asset compatibility cannot be asserted from the PDF. A BeatMeat coverage table must distinguish independently implemented functionality, partial approximations, unimplemented items and unavailable licensed content. All device names above identify the reference being analyzed, not a license to label unrelated implementations as equivalent products.

## Page-by-page review inventory

Every page below was read in full as extracted text. Ranges in the specification above summarize cross-page requirements; this table records the contiguous coverage and the active section on each PDF page. Blank headings on continuation pages inherit the preceding section. Text-accessible diagram labels were included. PDF269, PDF313 and PDF354 were additionally visually inspected; screenshot pixel measurements were not.

| PDF page | Printed page | Section/topic read |
|---|---|---|
|269|267|19.5.1 Programming a Fade-Out for a Live Set|
|270|268|19.5.2 Creating Long Loops from Short Loops|
|271|269|19.5.3 Imposing Rhythm Patterns onto Samples; 19.5.4 Clip Envelopes as LFOs|
|272|270|20.1 Importing Video; chapter 20 introduction|
|273|271|20.2 The Appearance of Video in Live; 20.2.1 Video Clips in the Arrangement View|
|274|272|20.2.2 The Video Window|
|275|273|20.2.3 Clip View|
|276|274|20.3 Matching Sound to Video|
|277|275|20.4 Video Trimming Tricks|
|278|276|20.4 Video Trimming Tricks|
|279|277|21.1 Auto Filter; chapter 21 introduction|
|280|278|21.1 Auto Filter; chapter 21 introduction|
|281|279|21.2 Auto Pan|
|282|280|21.3 Beat Repeat|
|283|281|21.3 Beat Repeat|
|284|282|21.4 Chorus|
|285|283|21.5 Compressor|
|286|284|21.5 Compressor|
|287|285|21.5 Compressor|
|288|286|21.5.1 Sidechain Parameters|
|289|287|21.5.2 Compression Tips|
|290|288|21.5.2 Compression Tips|
|291|289|21.6 Corpus|
|292|290|21.6 Corpus|
|293|291|21.6 Corpus|
|294|292|21.6 Corpus|
|295|293|21.7 Dynamic Tube|
|296|294|21.8 EQ Eight|
|297|295|21.8 EQ Eight|
|298|296|21.9 EQ Three|
|299|297|21.10 Erosion|
|300|298|21.11 External Audio Effect|
|301|299|21.12 Filter Delay|
|302|300|21.12 Filter Delay|
|303|301|21.13 Flanger|
|304|302|21.14 Frequency Shifter|
|305|303|21.14 Frequency Shifter|
|306|304|21.14.1 Frequency Shifter Tips|
|307|305|21.15 Gate|
|308|306|21.16 Grain Delay|
|309|307|21.16 Grain Delay|
|310|308|21.17 Limiter|
|311|309|21.18 Looper|
|312|310|21.18 Looper|
|313|311|21.18 Looper|
|314|312|21.18 Looper|
|315|313|21.18.1 Feedback Routing|
|316|314|21.19 Multiband Dynamics|
|317|315|21.19.1 Dynamics Processing Theory|
|318|316|21.19.2 Interface and Controls|
|319|317|21.19.2 Interface and Controls|
|320|318|21.19.3 Multiband Dynamics Tips|
|321|319|21.19.3 Multiband Dynamics Tips|
|322|320|21.20 Overdrive|
|323|321|21.21 Phaser|
|324|322|21.22 Ping Pong Delay|
|325|323|21.22 Ping Pong Delay|
|326|324|21.23 Redux|
|327|325|21.24 Resonators|
|328|326|21.25 Reverb; 21.25.1 Input Processing|
|329|327|21.25.2 Early Re ections; 21.25.3 Global Settings|
|330|328|21.25.4 Diffusion Network; 21.25.5 Output|
|331|329|21.26 Saturator|
|332|330|21.26 Saturator|
|333|331|21.27 Simple Delay|
|334|332|21.28 Spectrum|
|335|333|21.28 Spectrum|
|336|334|21.29 Utility|
|337|335|21.30 Vinyl Distortion|
|338|336|21.31 Vocoder|
|339|337|21.31 Vocoder|
|340|338|21.31.1 Vocoder Tips|
|341|339|21.31.1 Vocoder Tips|
|342|340|22.1 Arpeggiator; chapter 22 introduction|
|343|341|22.1.1 Style and Rate Sections|
|344|342|22.1.1 Style and Rate Sections|
|345|343|22.1.2 Transposition and Velocity Sections|
|346|344|22.2 Chord|
|347|345|22.3 Note Length|
|348|346|22.4 Pitch|
|349|347|22.5 Random|
|350|348|22.6 Scale|
|351|349|22.7 Velocity|
|352|350|22.7 Velocity|
|353|351|23.1 Analog; chapter 23 introduction|
|354|352|23.1.1 Architecture and Interface|
|355|353|23.1.2 Oscillators|
|356|354|23.1.2 Oscillators|
|357|355|23.1.3 Noise Generator|
|358|356|23.1.4 Filters|
|359|357|23.1.5 Ampli ers|
|360|358|23.1.6 Envelopes|
|361|359|23.1.7 LFOs|
|362|360|23.1.8 Global Parameters|
|363|361|23.1.8 Global Parameters|
|364|362|23.1.8 Global Parameters|
|365|363|23.2 Collision; 23.2.1 Architecture and Interface|
|366|364|23.2.2 Excitator Tab|
|367|365|23.2.2 Excitator Tab|
|368|366|23.2.3 Resonator Tabs|
|369|367|23.2.3 Resonator Tabs|
|370|368|23.2.3 Resonator Tabs|
|371|369|23.2.3 Resonator Tabs|
|372|370|23.2.4 LFO Tab|
|373|371|23.2.5 MIDI Tab|
|374|372|23.2.5 MIDI Tab|
|375|373|23.2.6 Sound Design Tips|
|376|374|23.3 Drum Machines; 23.3.1 Drum Machines Installation|
|377|375|23.3.2 Accessing the Drum Machines; 23.4 Electric|
|378|376|23.4.1 Architecture and Interface; 23.4.2 Mallet Section|
|379|377|23.4.3 Fork Section; 23.4.4 Damper Section|
|380|378|23.4.5 Pickup Section; 23.4.6 Global Section|
|381|379|23.5 External Instrument|
|382|380|23.5 External Instrument|
|383|381|23.6 Impulse|
|384|382|23.6.1 Sample Slots|
|385|383|23.6.2 Start, Tune and Stretch; 23.6.3 Filter; 23.6.4 Saturator and Envelope|
|386|384|23.6.5 Pan and Volume; 23.6.6 Global Controls; 23.6.7 Individual Outputs; 23.7 Latin Percussion|
|387|385|23.7.1 Latin Percussion Installation; 23.7.2 Accessing the Latin Percussion Presets; 23.7.3 Modifying the Drum Racks|
|388|386|23.8 Operator|
|389|387|23.8.1 General Overview|
|390|388|23.8.2 Oscillator Section|
|391|389|23.8.2 Oscillator Section|
|392|390|23.8.2 Oscillator Section|
|393|391|23.8.2 Oscillator Section|
|394|392|23.8.3 LFO Section|
|395|393|23.8.4 Envelopes|
|396|394|23.8.4 Envelopes|
|397|395|23.8.5 Filter Section|
|398|396|23.8.6 Global Controls|
|399|397|23.8.7 Glide and Spread; 23.8.8 Strategies for Saving CPU Power|
|400|398|23.8.9 Finally...; 23.8.10 The Complete Parameter List|
|401|399|23.8.9 Finally...; 23.8.10 The Complete Parameter List|
|402|400|23.8.9 Finally...; 23.8.10 The Complete Parameter List|

## Visual cross-checks

- **PDF269:** Envelope screenshot visibly separates region/loop position and length from clip/sample controls, shows Unlinked and a long descending one-shot envelope. This supports independent envelope time-domain storage.
- **PDF313:** Looper diagram confirms Empty→Record→Play single-click transitions, bidirectional Play/Overdub single clicks, stop transitions by double click, Hold clear from Stopped and Hold undo/redo from Play. Gesture types are distinct arrows, not extra playback states.
- **PDF354:** Analog diagram shows oscillator/noise inputs into a pre-filter mixer; two filter/amp audio paths feeding a stereo output; a Filter1→Filter2 audio route; dotted modulation paths from the associated LFO/filter-envelope/amp-envelope blocks. Audio routing and modulation routing must remain separate structures.

The separate `DEVICE_CATALOG.json` catalogs all 52 top-level chapter21–23 entries, including the remainder of chapter23 outside this report's range. Source bounds and important control groups are original summaries. Every entry is explicitly `not implemented` until the application supplies and verifies the corresponding behavior.
