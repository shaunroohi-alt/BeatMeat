# BeatMeat manual blueprint index

The supplied reference is **Ableton Reference Manual Version 8**, Live 8.0.2 (May 2009), 534 physical PDF pages. The reports below paraphrase functional behavior for independent BeatMeat engineering. They are not implementation-status claims. The manual supplies product behavior, not source code, proprietary DSP equations, external sample libraries, plugin binaries, or permission to impersonate vendor services.

## Review ranges

| Physical PDF pages | Report | Review scope |
|---|---|---|
| 1–134 | [Pages 001–134](manual-pages-001-134.md) | All extracted text read; representative figures visually inspected on pages 16, 24, 69, 84, 94, 107 |
| 135–268 | [Pages 135–268](manual-pages-135-268.md) | All extracted text read; figures inspected on PDF pages 176, 196, 244 |
| 269–402 | [Pages 269–402](manual-pages-269-402.md) | All extracted text read; figures inspected on PDF pages 269, 313, 354 |
| 403–534 | [Pages 403–534](manual-pages-403-534.md) | All extracted text read; figures/glyphs inspected on PDF pages 488, 506, 507, 510, 519, 520 |

PDF page positions include two front-matter pages, so printed page numbers are generally two less. Text extraction can omit symbol-based shortcuts and figure-only labels. Reviewing all extracted text is distinct from examining every image at pixel level.

## Full chapter inventory

Chapter bounds below were derived from chapter headings across the complete extracted manual. They identify the reference structure; they do not assert that the index author personally reviewed chapters outside the assigned first range. Feature implementation statuses and validation evidence must be added separately.

| Chapter | Reference title | Physical PDF pages | Implementation / validation |
|---|---|---|---|
| 1 | Welcome to Live | 3–6 | See implementation coverage record; not implied by manual review |
| 2 | First Steps | 7–11 | See implementation coverage record; not implied by manual review |
| 3 | Authorizing Live | 12–14 | See implementation coverage record; not implied by manual review |
| 4 | Live Concepts | 15–32 | See implementation coverage record; not implied by manual review |
| 5 | Managing Files and Sets | 33–74 | See implementation coverage record; not implied by manual review |
| 6 | Arrangement View | 75–90 | See implementation coverage record; not implied by manual review |
| 7 | Session View | 91–99 | See implementation coverage record; not implied by manual review |
| 8 | Clip View | 100–119 | See implementation coverage record; not implied by manual review |
| 9 | Tempo Control and Warping | 120–136 | See implementation coverage record; not implied by manual review |
| 10 | Editing MIDI Notes and Velocities | 137–150 | See implementation coverage record; not implied by manual review |
| 11 | Using Grooves | 151–156 | See implementation coverage record; not implied by manual review |
| 12 | Launching Clips | 157–165 | See implementation coverage record; not implied by manual review |
| 13 | Routing and I/O | 166–186 | See implementation coverage record; not implied by manual review |
| 14 | Mixing | 187–199 | See implementation coverage record; not implied by manual review |
| 15 | Recording New Clips | 200–210 | See implementation coverage record; not implied by manual review |
| 16 | Working with Instruments and Effects | 211–230 | See implementation coverage record; not implied by manual review |
| 17 | Instrument, Drum and Effect Racks | 231–252 | See implementation coverage record; not implied by manual review |
| 18 | Automation and Editing Envelopes | 253–259 | See implementation coverage record; not implied by manual review |
| 19 | Clip Envelopes | 260–271 | See implementation coverage record; not implied by manual review |
| 20 | Working with Video | 272–278 | See implementation coverage record; not implied by manual review |
| 21 | Live Audio Effect Reference | 279–341 | See implementation coverage record; not implied by manual review |
| 22 | Live MIDI Effect Reference | 342–352 | See implementation coverage record; not implied by manual review |
| 23 | Live Instrument Reference | 353–448 | See implementation coverage record; not implied by manual review |
| 24 | Max For Live | 449–450 | See implementation coverage record; not implied by manual review |
| 25 | Sharing Live Sets | 451–454 | See implementation coverage record; not implied by manual review |
| 26 | MIDI and Key Remote Control | 455–467 | See implementation coverage record; not implied by manual review |
| 27 | Using the APC40 | 468–478 | See implementation coverage record; not implied by manual review |
| 28 | Synchronization and ReWire | 479–484 | See implementation coverage record; not implied by manual review |
| 29 | Computer Audio Resources and Strategies | 485–490 | See implementation coverage record; not implied by manual review |
| 30 | Audio Fact Sheet | 491–501 | See implementation coverage record; not implied by manual review |
| 31 | MIDI Fact Sheet | 502–509 | See implementation coverage record; not implied by manual review |
| 32 | Live Keyboard Shortcuts | 510–521 | See implementation coverage record; not implied by manual review |

| — | Alphabetical index | 522–534 | Reference lookup, not a separate software feature |

## Blueprint-wide invariants

- Session and Arrangement share track identities, devices, routing and mixer; switching the visible view does not change sound or transport.
- A Session launch overrides that track's Arrangement; stopping the Session clip does not itself restore Arrangement.
- Separate song tempo/meter, musical time, source media time and rendered sample time. Source region, launch start and loop interval are distinct.
- Audio clips reference media; MIDI clips embed event data. Portability needs explicit dependency collection and missing-media handling.
- Exports, recordings, consolidation and freezes have different signal-tap points; verify each against real audio results.
- Do not expose a control as working unless it changes observable musical behavior and persists correctly.
- Vendor authorization, online collaboration endpoints, factory packs and dedicated hardware integrations are separate capabilities and external prerequisites.
- Build, installation, signing/notarization, runtime audio and feature parity need separate evidence.
