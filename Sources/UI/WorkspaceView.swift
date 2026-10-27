import SwiftUI
import AppKit

private enum MeatPalette {
    static let background = Color(red: 0.055, green: 0.066, blue: 0.080)
    static let panel = Color(red: 0.085, green: 0.099, blue: 0.116)
    static let elevated = Color(red: 0.115, green: 0.132, blue: 0.153)
    static let line = Color.white.opacity(0.09)
    static let coral = Color(red: 1.0, green: 0.40, blue: 0.31)
    static let teal = Color(red: 0.24, green: 0.83, blue: 0.75)
    static let muted = Color(red: 0.52, green: 0.57, blue: 0.63)
    static let trackColors: [Color] = [coral, teal, Color(red: 0.66, green: 0.56, blue: 0.98), Color(red: 0.96, green: 0.72, blue: 0.35), Color(red: 0.38, green: 0.66, blue: 0.96), Color(red: 0.91, green: 0.47, blue: 0.71)]
    static func track(_ index: Int) -> Color { trackColors[abs(index % trackColors.count)] }
}

@MainActor
struct WorkspaceView: View {
    @EnvironmentObject private var studio: Studio
    @State private var showGuide = false
    @State private var sidebarVisible = true

    var body: some View {
        VStack(spacing: 0) {
            transport
            Rectangle().fill(MeatPalette.line).frame(height: 1)
            HStack(spacing: 0) {
                if sidebarVisible {
                    browser.frame(width: 190)
                    Rectangle().fill(MeatPalette.line).frame(width: 1)
                }
                VStack(spacing: 0) {
                    workspaceHeader
                    if studio.mode == .session {
                        sessionView.frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        arrangementView.frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    Rectangle().fill(MeatPalette.line).frame(height: 1)
                    clipInspector.frame(height: 235)
                }
            }
            statusBar
        }
        .background(MeatPalette.background)
        .foregroundStyle(Color.white.opacity(0.88))
        .font(.system(size: 12))
        .frame(minWidth: 1050, minHeight: 780)
        .sheet(isPresented: $showGuide) { guide }
    }

    private var transport: some View {
        HStack(spacing: 18) {
            Button { sidebarVisible.toggle() } label: {
                Image(systemName: "sidebar.left").font(.system(size: 16))
            }.buttonStyle(.plain).help("Show or hide project browser")
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("BeatMeat").font(.system(size: 23, weight: .black, design: .rounded)).tracking(-0.7)
                Text("BY MP-AUDIO").font(.system(size: 8, weight: .bold)).tracking(1.0).foregroundStyle(MeatPalette.coral)
            }
            Divider().frame(height: 28)
            HStack(spacing: 6) {
                transportButton("play.fill", active: studio.playing, color: MeatPalette.teal, help: "Play transport") { studio.play() }
                transportButton("stop.fill", active: false, color: .white, help: "Stop transport") { studio.stop() }
                transportButton("record.circle.fill", active: studio.recording, color: MeatPalette.coral, help: "Record microphone to the armed audio track") { studio.record() }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("POSITION").font(.system(size: 8, weight: .bold)).foregroundStyle(MeatPalette.muted)
                Text(positionText).font(.system(size: 18, weight: .medium, design: .monospaced)).monospacedDigit()
            }.frame(width: 96, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text("TEMPO").font(.system(size: 8, weight: .bold)).foregroundStyle(MeatPalette.muted)
                TextField("BPM", value: $studio.project.bpm, format: .number.precision(.fractionLength(1)))
                    .textFieldStyle(.plain).font(.system(size: 17, weight: .medium, design: .monospaced))
                    .frame(width: 64).onSubmit { studio.updateTransport() }
                    .help("Project tempo in beats per minute; press Return to apply")
            }
            Text("4 / 4").font(.system(size: 11, design: .monospaced)).foregroundStyle(MeatPalette.muted)
            Toggle(isOn: $studio.project.loopEnabled) {
                Image(systemName: "repeat").font(.system(size: 14, weight: .semibold))
            }.toggleStyle(.button).tint(MeatPalette.teal)
                .onChange(of: studio.project.loopEnabled) { _, _ in studio.updateTransport() }
                .help("Loop the project between its loop markers")
            Spacer(minLength: 10)
            Button { studio.backToArrangement() } label: {
                Label("To arrangement", systemImage: "arrow.uturn.backward")
                    .font(.system(size: 10, weight: .medium))
            }.buttonStyle(.bordered).help("Return all tracks to Arrangement playback")
            Button { showGuide = true } label: { Image(systemName: "questionmark.circle") }
                .buttonStyle(.plain).help("Workflow guide and current implementation coverage")
        }
        .padding(.horizontal, 18).padding(.vertical, 13)
        .background(MeatPalette.panel)
    }

    private func transportButton(_ image: String, active: Bool, color: Color, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: image).font(.system(size: 17, weight: .semibold))
                .foregroundStyle(active ? MeatPalette.background : color)
                .frame(width: 37, height: 33)
                .background(active ? color : MeatPalette.elevated, in: RoundedRectangle(cornerRadius: 6))
        }.buttonStyle(.plain).help(help)
    }

    private var positionText: String {
        let beat = max(0, studio.beat)
        return String(format: "%03d.%d.%02d", Int(beat / 4) + 1, Int(beat.truncatingRemainder(dividingBy: 4)) + 1, Int(beat.truncatingRemainder(dividingBy: 1) * 100))
    }

    private var browser: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeading("PROJECT")
            Text(studio.project.name).font(.system(size: 15, weight: .semibold)).lineLimit(2)
                .padding(.horizontal, 16).padding(.bottom, 16)
            browserAction("New project", image: "doc.badge.plus", action: studio.newProject)
            browserAction("Open project…", image: "folder", action: studio.open)
            browserAction("Save project…", image: "square.and.arrow.down", action: studio.save)
            Divider().padding(.vertical, 15)
            sectionHeading("CREATE")
            browserAction("Audio track", image: "waveform") { studio.addTrack(.audio) }
                .disabled(studio.project.tracks.count >= 16)
            browserAction("MIDI track", image: "pianokeys") { studio.addTrack(.midi) }
                .disabled(studio.project.tracks.count >= 16)
            browserAction("Import audio…", image: "square.and.arrow.down.on.square", action: studio.importAudio)
            browserAction("Import MIDI…", image: "pianokeys.inverse", action: studio.importMIDI)
            browserAction("MIDI clip", image: "square.grid.3x3", action: studio.newMIDIClip)
            Divider().padding(.vertical, 15)
            sectionHeading("DELIVER")
            browserAction("Export stereo WAV…", image: "square.and.arrow.up", action: studio.exportWAV)
            browserAction("Export MIDI clip…", image: "music.note.list", action: studio.exportMIDI)
            Spacer(minLength: 20)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle().fill(MeatPalette.teal).frame(width: 5, height: 5)
                    Text("NATIVE AUDIO ENGINE").font(.system(size: 8, weight: .bold)).tracking(0.8)
                }
                Text("Session clips and a shared arrangement. Audio and MIDI, built for macOS.")
                    .font(.system(size: 10)).foregroundStyle(MeatPalette.muted).fixedSize(horizontal: false, vertical: true)
                Button("Implementation notes") { showGuide = true }
                    .font(.system(size: 10)).buttonStyle(.link)
            }.padding(16)
        }.background(MeatPalette.panel.opacity(0.65))
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title).font(.system(size: 9, weight: .bold)).tracking(1.5)
            .foregroundStyle(MeatPalette.muted).padding(.horizontal, 16).padding(.top, 18).padding(.bottom, 10)
    }

    private func browserAction(_ title: String, image: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: image).frame(width: 16).foregroundStyle(MeatPalette.muted)
                Text(title).font(.system(size: 11))
                Spacer()
            }.padding(.horizontal, 16).padding(.vertical, 9).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private var workspaceHeader: some View {
        HStack(spacing: 12) {
            Picker("Workspace", selection: $studio.mode) {
                Text("SESSION").tag(WorkspaceMode.session)
                Text("ARRANGEMENT").tag(WorkspaceMode.arrangement)
            }.pickerStyle(.segmented).frame(width: 245)
                .onChange(of: studio.mode) { _, _ in studio.updateTransport() }
            Spacer()
            if studio.mode == .session {
                Text("CLIP LAUNCH • BAR QUANTIZED").font(.system(size: 8, weight: .medium)).tracking(1)
                    .foregroundStyle(MeatPalette.muted)
            } else {
                Text("LOOP").font(.system(size: 8, weight: .bold)).foregroundStyle(MeatPalette.muted)
                TextField("Start", value: $studio.project.loopStart, format: .number.precision(.fractionLength(0...1)))
                    .frame(width: 44).onSubmit { studio.updateTransport() }
                Text("→").foregroundStyle(MeatPalette.muted)
                TextField("End", value: $studio.project.loopEnd, format: .number.precision(.fractionLength(0...1)))
                    .frame(width: 44).onSubmit { studio.updateTransport() }
            }
        }.padding(.horizontal, 15).padding(.vertical, 11).background(MeatPalette.background)
    }

    private var sessionView: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 0) {
                HStack(alignment: .top, spacing: 1) {
                    ForEach(Array(studio.project.tracks.enumerated()), id: \.element.id) { index, track in
                        sessionColumn(index, track: track).frame(width: 146)
                    }
                    if studio.project.tracks.isEmpty { emptyWorkspace }
                }.padding(.horizontal, 12).padding(.bottom, 12)
                VStack(spacing: 3) {
                    Text("SCENES").font(.system(size: 8, weight: .bold)).tracking(1)
                        .foregroundStyle(MeatPalette.muted).frame(height: 38)
                    ForEach(0..<8, id: \.self) { slot in
                        Button { studio.launchScene(slot) } label: {
                            HStack {
                                Text(String(format: "%02d", slot + 1)).font(.system(size: 10, design: .monospaced))
                                Image(systemName: "play.fill").font(.system(size: 9))
                            }.frame(width: 64, height: 41).background(MeatPalette.elevated, in: RoundedRectangle(cornerRadius: 4))
                        }.buttonStyle(.plain).help("Launch scene \(slot + 1) at the next bar")
                    }
                    VStack(spacing: 5) {
                        Text("MASTER").font(.system(size: 8, weight: .bold)).foregroundStyle(MeatPalette.muted)
                        Slider(value: $studio.master, in: 0...1).tint(MeatPalette.teal)

                        Text(gainText(studio.master)).font(.system(size: 9, design: .monospaced))
                    }.padding(10).padding(.top, 10)
                }.frame(width: 84).padding(.trailing, 8).background(MeatPalette.panel.opacity(0.45))
            }
        }
    }

    private func sessionColumn(_ index: Int, track: BeatTrack) -> some View {
        VStack(spacing: 3) {
            trackHeading(index, track: track)
            ForEach(0..<8, id: \.self) { slot in
                sessionCell(index, slot: slot, track: track)
            }
            channelMixer(index, track: track).padding(.top, 9)
        }.padding(.horizontal, 4)
            .background(studio.selectedTrack == index ? MeatPalette.elevated.opacity(0.46) : MeatPalette.panel.opacity(0.25))
    }

    private func trackHeading(_ index: Int, track: BeatTrack) -> some View {
        HStack(spacing: 5) {
            Image(systemName: track.kind == .audio ? "waveform" : "pianokeys").font(.system(size: 10))
            Text(track.name).font(.system(size: 11, weight: .semibold)).lineLimit(1)
            Spacer(minLength: 0)
            Button { studio.launch(track: index, slot: -1) } label: {
                Image(systemName: "stop.fill").font(.system(size: 8))
            }.buttonStyle(.plain).help("Stop Session clips on \(track.name)")
        }.foregroundStyle(MeatPalette.track(track.color)).frame(height: 38)
            .padding(.horizontal, 5).contentShape(Rectangle())
            .onTapGesture { studio.select(track: index, slot: studio.selectedSlot) }
    }

    private func sessionCell(_ index: Int, slot: Int, track: BeatTrack) -> some View {
        let clip = track.clips.first { $0.slot == slot }
        let selected = studio.selectedTrack == index && studio.selectedSlot == slot
        let active = studio.playing && studio.activeSlots[index] == slot
        let color = MeatPalette.track(track.color)
        return HStack(spacing: 0) {
            if clip != nil {
                Button { studio.launch(track: index, slot: slot) } label: {
                    Image(systemName: "play.fill").font(.system(size: 9)).frame(width: 25, height: 41)
                }.buttonStyle(.plain).help("Launch clip at the next bar")
            }
            Button { studio.select(track: index, slot: slot) } label: {
                HStack {
                    if let clip {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(clip.name).font(.system(size: 10, weight: .medium)).lineLimit(1)
                            Text("\(clip.lengthBeats, specifier: "%.1f") beats")
                                .font(.system(size: 8, design: .monospaced)).foregroundStyle(Color.white.opacity(0.45))
                        }
                    } else {
                        Image(systemName: "plus").font(.system(size: 9)).foregroundStyle(MeatPalette.muted.opacity(0.45))
                    }
                    Spacer(minLength: 3)
                }.padding(.leading, clip == nil ? 10 : 0).frame(maxWidth: .infinity, minHeight: 41)
                    .contentShape(Rectangle())
            }.buttonStyle(.plain)
        }.foregroundStyle(clip == nil ? MeatPalette.muted : color)
            .background(clip == nil ? MeatPalette.background.opacity(0.7) : color.opacity(active ? 0.4 : 0.15), in: RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(selected ? color : MeatPalette.line, lineWidth: selected ? 1.5 : 0.5))
    }

    private func channelMixer(_ index: Int, track: BeatTrack) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                mixerToggle("M", active: track.mute, color: .orange) {
                    studio.project.tracks[index].mute.toggle(); studio.updateTrack(index)
                }.help("Mute")
                mixerToggle("S", active: track.solo, color: MeatPalette.teal) {
                    studio.project.tracks[index].solo.toggle(); studio.updateTrack(index)
                }.help("Solo")
                mixerToggle("●", active: track.armed, color: MeatPalette.coral) {
                    studio.project.tracks[index].armed.toggle(); studio.updateTrack(index)
                }.help("Arm for audio input recording")
            }
            HStack(spacing: 7) {
                Text("PAN").font(.system(size: 8, weight: .medium)).foregroundStyle(MeatPalette.muted)
                Slider(value: trackBinding(index, \.pan), in: -1...1).tint(MeatPalette.track(track.color))
            }
            HStack(spacing: 7) {
                Text("VOL").font(.system(size: 8, weight: .medium)).foregroundStyle(MeatPalette.muted)
                Slider(value: trackBinding(index, \.gain), in: 0...1.5).tint(MeatPalette.track(track.color))
            }
            HStack {
                Text(gainText(track.gain)).font(.system(size: 9, design: .monospaced))
                Spacer()
                levelMeter(index).frame(width: 60, height: 5)
            }
            HStack(spacing: 7) {
                Text("ECHO").font(.system(size: 8, weight: .medium)).foregroundStyle(MeatPalette.muted)
                Slider(value: trackBinding(index, \.send), in: 0...1).tint(MeatPalette.teal)
                    .help("Send to the shared stereo echo return")
            }
            HStack(spacing: 7) {
                Text("LPF").font(.system(size: 8, weight: .medium)).foregroundStyle(MeatPalette.muted)
                Slider(value: cutoffBinding(index), in: log10(20)...log10(20_000)).tint(MeatPalette.track(track.color))
                    .help("One-pole low-pass cutoff: \(Int(track.cutoff)) Hz")
                Text(track.cutoff >= 1000 ? String(format: "%.1fk", track.cutoff / 1000) : String(format: "%.0f", track.cutoff))
                    .font(.system(size: 8, design: .monospaced)).frame(width: 28, alignment: .trailing)
            }
        }.padding(.horizontal, 8).padding(.bottom, 12)
    }

    private func trackBinding(_ index: Int, _ keyPath: WritableKeyPath<BeatTrack, Double>) -> Binding<Double> {
        Binding(get: { studio.project.tracks[index][keyPath: keyPath] }, set: { value in
            guard studio.project.tracks.indices.contains(index) else { return }
            studio.project.tracks[index][keyPath: keyPath] = value
            studio.updateTrack(index)
        })
    }

    private func cutoffBinding(_ index: Int) -> Binding<Double> {
        Binding(get: { log10(max(20, min(20_000, studio.project.tracks[index].cutoff))) }, set: { value in
            guard studio.project.tracks.indices.contains(index) else { return }
            studio.project.tracks[index].cutoff = pow(10, value)
            studio.updateTrack(index)
        })
    }

    private func mixerToggle(_ title: String, active: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: 10, weight: .bold)).frame(maxWidth: .infinity).frame(height: 23)
                .foregroundStyle(active ? MeatPalette.background : MeatPalette.muted)
                .background(active ? color : MeatPalette.elevated, in: RoundedRectangle(cornerRadius: 3))
        }.buttonStyle(.plain)
    }

    private func levelMeter(_ index: Int) -> some View {
        let peak = studio.meters.indices.contains(index) ? Double(studio.meters[index]) : 0
        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.05))
                Capsule().fill(peak > 0.95 ? MeatPalette.coral : MeatPalette.teal)
                    .frame(width: geometry.size.width * min(1, max(0, peak)))
            }
        }
    }

    private func gainText(_ gain: Double) -> String {
        gain > 0.0001 ? String(format: "%+.1f dB", 20 * log10(gain)) : "−∞ dB"
    }

    private var arrangementView: some View {
        VStack(spacing: 0) {
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 1) {
                    arrangementRuler
                    ForEach(Array(studio.project.tracks.enumerated()), id: \.element.id) { index, track in
                        HStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(track.name).font(.system(size: 11, weight: .semibold)).foregroundStyle(MeatPalette.track(track.color))
                                HStack {
                                    Text(track.kind == .audio ? "AUDIO" : "MIDI").font(.system(size: 8, weight: .bold)).foregroundStyle(MeatPalette.muted)
                                    levelMeter(index).frame(width: 55, height: 4)
                                }
                            }.frame(width: 132, alignment: .leading).padding(.leading, 12)
                                .frame(height: 65).background(MeatPalette.panel)
                            arrangementLane(index, track: track)
                        }
                    }
                    if studio.project.tracks.isEmpty { emptyWorkspace.frame(width: 800, height: 240) }
                }.padding(12)
            }
            HStack {
                Image(systemName: "cursorarrow.motionlines").foregroundStyle(MeatPalette.muted)
                Text("Select a region to edit its start and length below. Clip positions use beats from project start.")
                    .font(.system(size: 9)).foregroundStyle(MeatPalette.muted)
                Spacer()
            }.padding(10).background(MeatPalette.panel.opacity(0.5))
        }
    }

    private var timelineBeats: Double {
        let ends = studio.project.tracks.flatMap(\.clips).compactMap { clip -> Double? in
            let end = clip.startBeat + clip.lengthBeats
            return end.isFinite ? min(100_000, max(0, end)) : nil
        }
        return max(64, ends.max() ?? 64)
    }
    private var timelineWidth: CGFloat { CGFloat(min(4096, timelineBeats)) * 22 }

    private var arrangementRuler: some View {
        HStack(spacing: 0) {
            Text("TRACKS").font(.system(size: 8, weight: .bold)).foregroundStyle(MeatPalette.muted)
                .frame(width: 144, alignment: .leading)
            Canvas { context, size in
                for bar in 0...Int(min(4096, timelineBeats) / 4) {
                    let x = CGFloat(bar) * 88
                    context.draw(Text("\(bar + 1)").font(.system(size: 9, design: .monospaced)).foregroundColor(.gray), at: CGPoint(x: x + 6, y: 12), anchor: .leading)
                    var path = Path(); path.move(to: CGPoint(x: x, y: 24)); path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(.white.opacity(0.1)), lineWidth: 1)
                }
            }.frame(width: timelineWidth, height: 32)
        }
    }

    private func arrangementLane(_ index: Int, track: BeatTrack) -> some View {
        ZStack(alignment: .leading) {
            Canvas { context, size in
                for beat in 0...Int(min(4096, timelineBeats)) {
                    let x = CGFloat(beat) * 22
                    var path = Path(); path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(.white.opacity(beat % 4 == 0 ? 0.1 : 0.035)), lineWidth: 0.5)
                }
                let x = CGFloat(studio.beat) * 22
                var playhead = Path(); playhead.move(to: CGPoint(x: x, y: 0)); playhead.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(playhead, with: .color(MeatPalette.coral), lineWidth: 1)
            }
            ForEach(track.clips) { clip in
                Button { studio.select(track: index, slot: clip.slot) } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(clip.name).font(.system(size: 9, weight: .semibold)).lineLimit(1)
                        if track.kind == .audio {
                            MiniWaveform(samples: clip.waveform, color: MeatPalette.track(track.color)).frame(height: 23)
                        } else {
                            Text("\(clip.notes.count) MIDI notes").font(.system(size: 8)).opacity(0.6)
                            Spacer(minLength: 0)
                        }
                    }.padding(6).frame(width: max(40, CGFloat(clip.lengthBeats.isFinite ? min(4096, max(0.0625, clip.lengthBeats)) : 4) * 22), height: 56, alignment: .topLeading)
                        .background(MeatPalette.track(track.color).opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(MeatPalette.track(track.color).opacity(studio.selectedTrack == index && studio.selectedSlot == clip.slot ? 1 : 0.4), lineWidth: 1))
                }.buttonStyle(.plain).offset(x: CGFloat(clip.startBeat.isFinite ? min(100_000, max(0, clip.startBeat)) : 0) * 22)
            }
        }.frame(width: timelineWidth, height: 65).background(MeatPalette.panel.opacity(0.3)).clipped()
    }

    @ViewBuilder
    private var clipInspector: some View {
        if let clip = studio.selectedClip, studio.project.tracks.indices.contains(studio.selectedTrack) {
            let track = studio.project.tracks[studio.selectedTrack]
            HStack(spacing: 0) {
                clipControls(clip, track: track).frame(width: 228)
                Rectangle().fill(MeatPalette.line).frame(width: 1)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(track.kind == .midi ? "NOTE EDITOR" : "AUDIO CLIP").font(.system(size: 9, weight: .bold)).tracking(1.2)
                        Spacer()
                        Text(track.kind == .midi ? "Click grid to add notes · Select a note to edit" : "Original sample playback · Tempo changes pitch · No Warp processing")
                            .font(.system(size: 9)).foregroundStyle(MeatPalette.muted)
                    }
                    if track.kind == .midi {
                        PianoRoll(clip: clip, color: MeatPalette.track(track.color))
                    } else {
                        MiniWaveform(samples: clip.waveform, color: MeatPalette.track(track.color))
                            .padding(.vertical, 12).background(MeatPalette.background, in: RoundedRectangle(cornerRadius: 6))
                        Text(clip.audioPath.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "No audio file")
                            .font(.system(size: 9, design: .monospaced)).foregroundStyle(MeatPalette.muted).lineLimit(1)
                    }
                }.padding(14)
            }.background(MeatPalette.panel.opacity(0.8)).id(clip.id)
        } else {
            HStack(spacing: 24) {
                Image(systemName: "waveform.path").font(.system(size: 39, weight: .ultraLight)).foregroundStyle(MeatPalette.muted.opacity(0.5))
                VStack(alignment: .leading, spacing: 9) {
                    Text("A little space for your next idea.").font(.system(size: 18, weight: .medium))
                    Text("Select a clip slot, import audio, or create a MIDI clip to begin.")
                        .font(.system(size: 11)).foregroundStyle(MeatPalette.muted)
                    HStack {
                        Button("Import audio…", action: studio.importAudio)
                        Button("Create MIDI clip", action: studio.newMIDIClip)
                    }.padding(.top, 3)
                }
                Spacer()
            }.padding(30).frame(maxWidth: .infinity, maxHeight: .infinity).background(MeatPalette.panel.opacity(0.5))
        }
    }

    private func clipControls(_ clip: BeatClip, track: BeatTrack) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 2).fill(MeatPalette.track(track.color)).frame(width: 4, height: 18)
                TextField("Clip name", text: clipBinding(clip, \.name)).textFieldStyle(.plain).font(.system(size: 13, weight: .semibold))
                    .onSubmit { studio.updateClip() }
            }
            HStack {
                numericClipField("START / BEATS", value: clipBinding(clip, \.startBeat))
                numericClipField("LENGTH / BEATS", value: clipBinding(clip, \.lengthBeats))
            }
            Toggle("Loop clip", isOn: clipBinding(clip, \.loop)).font(.system(size: 11))
            HStack {
                Text("\(track.kind == .audio ? "AUDIO" : "MIDI SYNTH") · SLOT \(clip.slot + 1)")
                    .font(.system(size: 8, weight: .bold)).foregroundStyle(MeatPalette.muted)
                Spacer()
                Button(role: .destructive, action: studio.deleteClip) { Image(systemName: "trash") }.buttonStyle(.plain).help("Delete selected clip")
            }
            Spacer(minLength: 0)
            Text(track.kind == .audio ? "PCM clip with independent loop and arrangement placement." : "Built-in sine instrument. Notes are stored with the project.")
                .font(.system(size: 9)).foregroundStyle(MeatPalette.muted).fixedSize(horizontal: false, vertical: true)
        }.padding(16)
    }

    private func numericClipField(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 7, weight: .bold)).foregroundStyle(MeatPalette.muted)
            TextField(label, value: value, format: .number.precision(.fractionLength(0...2)))
                .font(.system(size: 12, design: .monospaced)).textFieldStyle(.roundedBorder)
        }
    }

    private func clipBinding<Value>(_ clip: BeatClip, _ keyPath: WritableKeyPath<BeatClip, Value>) -> Binding<Value> {
        Binding(get: {
            guard studio.project.tracks.indices.contains(studio.selectedTrack),
                  let found = studio.project.tracks[studio.selectedTrack].clips.first(where: { $0.id == clip.id }) else { return clip[keyPath: keyPath] }
            return found[keyPath: keyPath]
        }, set: { value in
            guard studio.project.tracks.indices.contains(studio.selectedTrack),
                  let found = studio.project.tracks[studio.selectedTrack].clips.firstIndex(where: { $0.id == clip.id }) else { return }
            studio.project.tracks[studio.selectedTrack].clips[found][keyPath: keyPath] = value
            studio.updateClip()
        })
    }

    private var emptyWorkspace: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up").font(.system(size: 32, weight: .ultraLight)).foregroundStyle(MeatPalette.coral)
            Text("Start with a track").font(.system(size: 18, weight: .medium))
            Text("Import a sample or sequence a MIDI instrument.").foregroundStyle(MeatPalette.muted)
            HStack {
                Button("Audio track") { studio.addTrack(.audio) }
                Button("MIDI track") { studio.addTrack(.midi) }
            }
        }.frame(width: 500, height: 330)
    }

    private var statusBar: some View {
        HStack(spacing: 8) {
            Circle().fill(studio.recording ? MeatPalette.coral : MeatPalette.teal).frame(width: 5, height: 5)
            Text(studio.status).font(.system(size: 10)).lineLimit(1)
            Spacer()
            Text("\(studio.project.tracks.count) TRACKS").font(.system(size: 8, weight: .medium)).foregroundStyle(MeatPalette.muted)
            Text("BEATMEAT / DEVELOPMENT").font(.system(size: 8, weight: .bold)).tracking(0.7).foregroundStyle(MeatPalette.muted)
        }.padding(.horizontal, 16).padding(.vertical, 9).background(MeatPalette.panel)
    }

    private var guide: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Make something with BeatMeat.").font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("MP-Audio • Native macOS workstation").foregroundStyle(MeatPalette.coral)
                }
                Spacer()
                Button("Done") { showGuide = false }.keyboardShortcut(.defaultAction)
            }
            Divider()
            guideRow("01", title: "Bring in your sound", detail: "Add an audio track and import a local file. Add a MIDI track and create a clip to write notes in the piano roll.")
            guideRow("02", title: "Play the grid or arrange a song", detail: "Session launches are bar-quantized. Scenes launch clip rows together. Arrangement uses each clip’s start and length in beats. To Arrangement returns tracks from Session overrides.")
            guideRow("03", title: "Shape, save, and export", detail: "Set track volume, pan, mute, solo, low-pass cutoff, and echo send. Arm an audio track for microphone recording. Save a project, then export its stereo mix as WAV.")
            Divider()
            Text("Current scope").font(.headline)
            Text("This is an independent development build. The 534-page reference manual is mapped in the project’s Docs folder. Advanced Warp algorithms, Ableton devices and sound libraries, AU/VST hosting, racks, groove extraction, external synchronization, and complete automation editing are not presented as working features here. Imported audio uses basic resampling; changing tempo changes pitch.")
                .font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Text("Use original or properly licensed audio. Device latency, recording, and performance must be checked on your Mac before live use.")
                .font(.system(size: 10)).foregroundStyle(.secondary)
        }.padding(30).frame(width: 660).background(MeatPalette.panel).foregroundStyle(.white)
    }

    private func guideRow(_ number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number).font(.system(size: 14, weight: .medium, design: .monospaced)).foregroundStyle(MeatPalette.coral)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(detail).font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct MiniWaveform: View {
    let samples: [Float]
    let color: Color
    var body: some View {
        Canvas { context, size in
            var line = Path()
            line.move(to: CGPoint(x: 0, y: size.height / 2))
            line.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            context.stroke(line, with: .color(color.opacity(0.15)), lineWidth: 1)
            guard !samples.isEmpty, size.width > 0 else { return }
            let bars = min(Int(size.width), samples.count)
            var waveform = Path()
            for i in 0..<bars {
                let sample = CGFloat(min(1, abs(samples[i * samples.count / bars])))
                let x = CGFloat(i) * size.width / CGFloat(bars)
                let half = max(0.4, sample * size.height * 0.45)
                waveform.move(to: CGPoint(x: x, y: size.height / 2 - half))
                waveform.addLine(to: CGPoint(x: x, y: size.height / 2 + half))
            }
            context.stroke(waveform, with: .color(color.opacity(0.85)), lineWidth: 1)
        }
    }
}

@MainActor
private struct PianoRoll: View {
    @EnvironmentObject private var studio: Studio
    let clip: BeatClip
    let color: Color
    @State private var selectedNote: UUID?
    @State private var lowPitch = 48
    private let rows = 24
    private var visibleLength: Double { clip.lengthBeats.isFinite ? min(4096, max(0.0625, clip.lengthBeats)) : 4 }
    var body: some View {
        VStack(spacing: 6) {
        GeometryReader { geometry in
            let keyWidth: CGFloat = 38
            let noteWidth = max(1, geometry.size.width - keyWidth)
            let rowHeight = geometry.size.height / CGFloat(rows)
            HStack(spacing: 0) {
                Canvas { context, size in
                    for row in 0..<rows {
                        let pitch = lowPitch + rows - 1 - row
                        let rect = CGRect(x: 0, y: CGFloat(row) * rowHeight, width: size.width, height: rowHeight)
                        context.fill(Path(rect), with: .color(blackKey(pitch) ? .black.opacity(0.6) : .white.opacity(0.13)))
                        if pitch % 12 == 0 {
                            context.draw(Text("C\(pitch / 12 - 1)").font(.system(size: 8)).foregroundColor(.gray), at: CGPoint(x: 8, y: rect.midY), anchor: .leading)
                        }
                    }
                }.frame(width: keyWidth)
                ZStack(alignment: .topLeading) {
                    Canvas { context, size in
                        for row in 0..<rows {
                            let pitch = lowPitch + rows - 1 - row
                            let rect = CGRect(x: 0, y: CGFloat(row) * rowHeight, width: size.width, height: rowHeight)
                            context.fill(Path(rect), with: .color(blackKey(pitch) ? .black.opacity(0.16) : .white.opacity(0.015)))
                            var line = Path(); line.move(to: rect.origin); line.addLine(to: CGPoint(x: size.width, y: rect.minY))
                            context.stroke(line, with: .color(.white.opacity(0.055)), lineWidth: 0.5)
                        }
                        let subdivisions = max(1, min(512, Int(visibleLength * 4)))
                        for beat in 0...subdivisions {
                            let x = CGFloat(beat) / CGFloat(subdivisions) * size.width
                            var line = Path(); line.move(to: CGPoint(x: x, y: 0)); line.addLine(to: CGPoint(x: x, y: size.height))
                            context.stroke(line, with: .color(.white.opacity(beat % 16 == 0 ? 0.2 : (beat % 4 == 0 ? 0.1 : 0.04))), lineWidth: 0.5)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(SpatialTapGesture().onEnded { value in
                        let pitch = min(lowPitch + rows - 1, max(lowPitch, lowPitch + rows - 1 - Int(value.location.y / max(1, rowHeight))))
                        let beat = max(0, min(visibleLength - 0.25, floor(Double(value.location.x / noteWidth) * visibleLength * 4) / 4))
                        studio.addNote(pitch: pitch, beat: beat)
                    })
                    ForEach(clip.notes.filter { $0.pitch >= lowPitch && $0.pitch < lowPitch + rows && $0.startBeat >= 0 && $0.startBeat < visibleLength && $0.duration.isFinite }) { note in
                        Button { selectedNote = note.id } label: {
                            RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.45 + note.velocity * 0.5))
                                .frame(width: min(noteWidth, max(5, CGFloat(min(visibleLength - note.startBeat, note.duration) / visibleLength) * noteWidth)), height: max(3, rowHeight - 1))
                                .overlay(RoundedRectangle(cornerRadius: 2).stroke(selectedNote == note.id ? Color.white : Color.clear, lineWidth: 1))
                        }.buttonStyle(.plain)
                            .offset(x: CGFloat(note.startBeat / max(0.0625, visibleLength)) * noteWidth,
                                    y: CGFloat(lowPitch + rows - 1 - note.pitch) * rowHeight)
                            .help("MIDI \(note.pitch) · \(note.duration) beats · select to edit")
                            .contextMenu { Button("Delete note", role: .destructive) { studio.removeNote(note.id); selectedNote = nil } }
                    }
                }
                .clipped()
            }.background(MeatPalette.background).clipShape(RoundedRectangle(cornerRadius: 5))
        }
        HStack(spacing: 8) {
            Button { lowPitch = max(0, lowPitch - 12) } label: { Image(systemName: "chevron.down") }.buttonStyle(.plain).help("Lower keyboard octave")
            Text("\(lowPitch)…\(lowPitch + rows - 1)").font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
            Button { lowPitch = min(104, lowPitch + 12) } label: { Image(systemName: "chevron.up") }.buttonStyle(.plain).help("Higher keyboard octave")
        if let note = clip.notes.first(where: { $0.id == selectedNote }) {
            HStack(spacing: 8) {
                Text("NOTE").foregroundStyle(.secondary)
                Stepper(value: noteBinding(note, \.pitch), in: 0...127) {
                    Text("\(note.pitch)").monospacedDigit().frame(width: 22)
                }.frame(width: 72)
                Text("START").foregroundStyle(.secondary)
                TextField("Beat", value: noteBinding(note, \.startBeat), format: .number.precision(.fractionLength(0...2))).frame(width: 42)
                Text("LENGTH").foregroundStyle(.secondary)
                TextField("Length", value: noteBinding(note, \.duration), format: .number.precision(.fractionLength(0...2))).frame(width: 42)
                Text("VELOCITY").foregroundStyle(.secondary)
                Slider(value: noteBinding(note, \.velocity), in: 0.01...1).tint(color).frame(maxWidth: 100)
                Spacer(minLength: 0)
                Button { studio.removeNote(note.id); selectedNote = nil } label: { Image(systemName: "trash") }.buttonStyle(.plain)
            }.font(.system(size: 8, weight: .medium)).frame(height: 21)
        } else {
            Text("1/16-note grid · Select a note to edit pitch, timing, length and velocity")
                .font(.system(size: 8)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).frame(height: 21)
        }
        }
        }
        .onAppear {
            if let pitch = clip.notes.map(\.pitch).min() { lowPitch = max(0, min(104, (pitch / 12) * 12)) }
        }
    }
    private func noteBinding<Value>(_ note: BeatNote, _ keyPath: WritableKeyPath<BeatNote, Value>) -> Binding<Value> {
        Binding(get: {
            guard studio.project.tracks.indices.contains(studio.selectedTrack),
                  let selectedClip = studio.project.tracks[studio.selectedTrack].clips.first(where: { $0.id == clip.id }),
                  let selected = selectedClip.notes.first(where: { $0.id == note.id }) else { return note[keyPath: keyPath] }
            return selected[keyPath: keyPath]
        }, set: { value in
            guard studio.project.tracks.indices.contains(studio.selectedTrack),
                  let clipIndex = studio.project.tracks[studio.selectedTrack].clips.firstIndex(where: { $0.id == clip.id }),
                  let noteIndex = studio.project.tracks[studio.selectedTrack].clips[clipIndex].notes.firstIndex(where: { $0.id == note.id }) else { return }
            studio.project.tracks[studio.selectedTrack].clips[clipIndex].notes[noteIndex][keyPath: keyPath] = value
            studio.updateClip()
        })
    }
    private func blackKey(_ pitch: Int) -> Bool { [1, 3, 6, 8, 10].contains(pitch % 12) }
}
