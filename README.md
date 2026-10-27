# BeatMeat by MP-Audio

Native macOS audio/MIDI workstation development source built from an independent engineering review of the supplied534-page Ableton Live8 manual. **Not a finished Live clone, not yet compiled for macOS or deployed.**

The source includes an original Session clip grid, Arrangement timeline, audio and MIDI tracks, piano-roll editing, scene/clip launch quantization, per-track Session overrides, a mixer, microphone recording path, save/open with collected audio, MIDI file interchange and offline WAV export. Demo notes are synthesized by the original sine instrument; no vendor sound library is included.

Read [feature coverage](Docs/FEATURE_COVERAGE.md) for the exact implemented subset and gaps, [the32-chapter blueprint](Docs/MANUAL_BLUEPRINT.md) for every reference chapter, and the four detailed review reports for behavior specifications. The supplied manual is retained in `Docs/Reference_Manual.pdf`.

## Run on a Mac

Requires macOS14+, Xcode with command-line tools selected, and Python3. No Apple team is needed for ad-hoc local development.

```sh
./script/build_and_run.sh
```

Or open `BeatMeat.xcodeproj`, select the BeatMeat scheme and My Mac, and run. The script is also wired to the Codex Run action. Use `--verify`, `--logs`, `--telemetry`, or `--debug` for the corresponding diagnostics. It launches a native .app bundle, not a web app or raw GUI executable.

## Validate and package

```sh
bash scripts/test-dsp.sh     # Portable C++ renderer:22 scenarios passed in this environment
swift test                   # Project/MIDI tests: require Swift; not yet executed here
bash scripts/package.sh      # Mac build, tests, native smoke, universal verification, signing, ZIP and DMG
bash scripts/install-macos.sh # Installs the built app into ~/Applications with an existing-app backup
```

The package script generates `dist/BeatMeat.app`, `BeatMeat-macOS.zip` and `BeatMeat-macOS.dmg` only after all required checks pass. No app/DMG is included in this source delivery. The optional `BEATMEAT_SIGN_IDENTITY` selects an existing local signing identity. Ad-hoc signing is the default; notarization and public distribution are not configured.

## Using the source implementation

- Play the included two-track MIDI sketch. Session launches enter on the next4-beat bar; scenes launch a row. Stopping a Session clip retains its override until Back to Arrangement.
- Add an Audio track or select the supplied one, then Import Audio. Full tracks are decoded into memory; use short unprotected stereo/mono audio. Loading and structural edits can interrupt playback.
- Select an empty slot on a MIDI track and create a MIDI clip. Click the piano roll to add notes; edit pitch, timing, duration and velocity below. Import/export standard MIDI via the menus.
- Arrangement clip placement and length use beats. Mixer changes affect the shared track; switching the visible view does not itself change audio ownership.
- Arm an Audio track, press Record and grant microphone access. Stop recording before editing or saving. Save the project to collect recorded/imported audio into its Media folder.
- Save/Open use `.beatmeat` project packages. WAV export renders Arrangement as44.1kHz stereo float audio, including mixer settings and a tail. It does not export transient Session ownership.

## Current validation and deployment blockers

The kernel passed22 scenarios with strict warnings, AddressSanitizer and UndefinedBehaviorSanitizer. Ten Swift inputs passed syntax parsing, which is not Swift type checking. Project references, plist, scheme and shell syntax were checked.

The current execution machine is Linux, with no Apple SDK. GitHub Actions jobs are blocked by account payments/spending limits, and the available GitHub integration cannot create a new repository. The requested destination is `shaunroohi-alt/BeatMeat`. The workspace remains authenticated as `sroohi`; switching to `shaunroohi-alt` failed because that account is not connected. No upload to the alternate account has occurred. Reconnect GitHub as `shaunroohi-alt` and grant repository access, then push and run the included workflow, or build locally on a Mac. Billing status for the alternate account has not been tested. Source review/test success does not establish native UI, hardware recording, signing or deployment success.
