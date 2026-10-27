import AppKit
import AVFoundation
import Combine
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class Studio: ObservableObject {
    @Published var project = BeatProject.demo()
    @Published var selectedTrack = 0
    @Published var selectedSlot = 0
    @Published var mode: WorkspaceMode = .session
    @Published var playing = false
    @Published var recording = false
    @Published var beat: Double = 0
    @Published var meters = Array(repeating: Float(0),count: 16)
    @Published var activeSlots = Array(repeating: -1,count: 16)
    @Published var status = "Ready · play the included MIDI sketch or import audio"
    @Published var error: String?
    @Published var master: Double = 0.8 { didSet { host?.setMaster(master) } }
    private var host: AudioHost?
    private var documentURL: URL?
    private var timer: AnyCancellable?
    private var dirty = false
    private var committed = BeatProject.demo()
    private var past: [BeatProject] = []
    private var future: [BeatProject] = []
    private var recordingTrack = 0
    private var recordingBeat: Double = 0
    private var recordingPermissionPending = false
    var selectedClip: BeatClip? {
        guard project.tracks.indices.contains(selectedTrack) else { return nil }
        return project.tracks[selectedTrack].clips.first {$0.slot == selectedSlot}
    }
    init() {
        committed = project
        do {
            let audio = try AudioHost(); try audio.replace(project,base: nil); audio.setMaster(master); host = audio
        } catch { self.error = error.localizedDescription }
        timer = Timer.publish(every: 1/30,on: .main,in: .common).autoconnect().sink { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }
    private func refresh() {
        guard let host else { return }
        beat = BMBeat(host.kernel)
        meters = (0..<16).map { Float(BMMeter(host.kernel,Int32($0))) }
        activeSlots = (0..<16).map { Int(BMActiveSlot(host.kernel,Int32($0))) }
    }
    func updateTransport() {
        guard project.bpm.isFinite, (20...300).contains(project.bpm), project.loopStart.isFinite,
              project.loopEnd.isFinite, project.loopStart >= 0, project.loopEnd > project.loopStart else {
            project.bpm = committed.bpm; project.loopStart = committed.loopStart; project.loopEnd = committed.loopEnd
            error = "Use a tempo from 20 to 300 BPM and a loop end greater than its start."; return
        }
        if let host { BMTransport(host.kernel,project.bpm,playing ? 1 : 0,0,project.loopEnabled ? 1 : 0,project.loopStart,project.loopEnd,4) }
        remember()
    }
    func play() {
        guard let host else { error = "Audio engine is unavailable."; return }
        do { try host.start(); playing.toggle(); updateTransportWithoutHistory() }
        catch { self.error = error.localizedDescription; playing = false }
    }
    func stop() {
        if recording { endRecording() }
        playing = false
        if let host { BMTransport(host.kernel,project.bpm,0,0,project.loopEnabled ? 1 : 0,project.loopStart,project.loopEnd,4); BMSeek(host.kernel,0) }
        beat = 0; status = "Stopped"
    }
    func backToArrangement() {
        if let host { BMBackToArrangement(host.kernel) }
        status = "Arrangement owns all tracks"
    }
    func launch(track: Int, slot: Int) {
        guard project.tracks.indices.contains(track), (-1..<8).contains(slot), let host else { return }
        if slot >= 0 && !project.tracks[track].clips.contains(where: {$0.slot == slot}) { select(track: track,slot: slot); return }
        if !playing { do { try host.start(); playing = true; updateTransportWithoutHistory() } catch { self.error = error.localizedDescription; return } }
        BMLaunch(host.kernel,Int32(track),Int32(slot)); select(track: track,slot: max(0,slot))
        status = slot < 0 ? "Track stop queued · next bar" : "Clip queued · next bar"
    }
    func launchScene(_ slot: Int) {
        for t in project.tracks.indices { launch(track: t,slot: project.tracks[t].clips.contains(where: {$0.slot == slot}) ? slot : -1) }
        status = "Scene \(slot+1) queued · next bar"
    }
    func select(track: Int,slot: Int) { guard project.tracks.indices.contains(track), (0..<8).contains(slot) else { return }; selectedTrack = track; selectedSlot = slot }
    func updateTrack(_ index: Int) {
        guard project.tracks.indices.contains(index), let host else { return }
        let track = project.tracks[index]
        guard track.gain.isFinite, (0...2).contains(track.gain), track.pan.isFinite, (-1...1).contains(track.pan), track.send.isFinite, (0...1).contains(track.send), track.cutoff.isFinite, (20...20000).contains(track.cutoff) else { error = "Mixer values are outside the supported range."; return }
        AudioHost.setTrack(host.kernel,track: track,index: index); remember()
    }
    func updateClip() { rebuild() }
    private func remember() {
        past.append(committed); if past.count > 100 { past.removeFirst() }
        committed = project; future.removeAll(); dirty = true
    }
    private func rebuild() {
        guard !recording else { project = committed; error = "Finish recording before editing clip structure."; return }
        do {
            try project.validate(); let oldBeat = beat
            try host?.replace(project,base: documentURL)
            if let host { BMSeek(host.kernel,oldBeat) }
            updateTransportWithoutHistory(); remember(); status = "Clip updated · audio engine refreshed"
        } catch { project = committed; selectedTrack = min(selectedTrack,max(0,project.tracks.count-1)); self.error = error.localizedDescription }
    }
    func undo() {
        guard !recording, let previous = past.popLast() else { return }
        do { try host?.replace(previous,base: documentURL); future.append(project); project = previous; committed = previous; dirty = true; updateTransportWithoutHistory() }
        catch { self.error = error.localizedDescription }
    }
    func redo() {
        guard !recording, let next = future.popLast() else { return }
        do { try host?.replace(next,base: documentURL); past.append(project); project = next; committed = next; dirty = true; updateTransportWithoutHistory() }
        catch { self.error = error.localizedDescription }
    }
    private func updateTransportWithoutHistory() { if let host { BMTransport(host.kernel,project.bpm,playing ? 1 : 0,0,project.loopEnabled ? 1 : 0,project.loopStart,project.loopEnd,4) } }
    func addTrack(_ kind: TrackKind) {
        guard project.tracks.count < 16 else { error = "This build supports up to 16 tracks."; return }
        project.tracks.append(BeatTrack(name: "\(project.tracks.count+1) · \(kind.rawValue.capitalized)",kind: kind,color: project.tracks.count%6))
        selectedTrack = project.tracks.count-1; selectedSlot = 0; rebuild()
    }
    func newMIDIClip() {
        guard project.tracks.indices.contains(selectedTrack), project.tracks[selectedTrack].kind == .midi else { error = "Select a MIDI track first."; return }
        guard selectedClip == nil else { return }
        project.tracks[selectedTrack].clips.append(BeatClip(slot: selectedSlot,name: "New pattern",startBeat: Double(selectedSlot)*4))
        rebuild()
    }
    func addNote(pitch: Int,beat: Double) {
        guard project.tracks.indices.contains(selectedTrack), let c = project.tracks[selectedTrack].clips.firstIndex(where: {$0.slot == selectedSlot}) else { return }
        guard project.tracks[selectedTrack].clips[c].notes.count < 64 else { error = "This build supports 64 notes per MIDI clip."; return }
        project.tracks[selectedTrack].clips[c].notes.append(BeatNote(pitch: min(127,max(0,pitch)),startBeat: max(0,(beat*4).rounded()/4)))
        rebuild()
    }
    func removeNote(_ id: UUID) {
        guard project.tracks.indices.contains(selectedTrack), let c = project.tracks[selectedTrack].clips.firstIndex(where: {$0.slot == selectedSlot}) else { return }
        project.tracks[selectedTrack].clips[c].notes.removeAll {$0.id == id}; rebuild()
    }
    func deleteClip() {
        guard project.tracks.indices.contains(selectedTrack) else { return }
        project.tracks[selectedTrack].clips.removeAll {$0.slot == selectedSlot}; rebuild()
    }
    func importAudio() {
        guard !recording else { error = "Finish recording before importing."; return }
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.audio]; panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try installAudio(url) } catch { self.error = error.localizedDescription }
    }
    private func installAudio(_ url: URL, start: Double? = nil) throws {
        let needsTrack = !project.tracks.indices.contains(selectedTrack) || project.tracks[selectedTrack].kind != .audio
        if needsTrack && project.tracks.count >= 16 { throw ProjectError.invalid }
        let decoded = try AudioHost.decode(url); let frames = Int(decoded.frameLength)
        guard let samples = decoded.floatChannelData?[0] else { throw ProjectError.invalid }
        var waveform = [Float](repeating: 0,count: 512)
        for i in waveform.indices {
            let low = i*frames/512, high = min(frames,max(low+1,(i+1)*frames/512))
            for j in low..<high { waveform[i] = max(waveform[i],abs(samples[j])) }
        }
        let length = Double(frames)/decoded.format.sampleRate*project.bpm/60
        if needsTrack {
            project.tracks.append(BeatTrack(name: "Audio",kind: .audio,color: project.tracks.count%6)); selectedTrack = project.tracks.count-1
        }
        let clip = BeatClip(slot: selectedSlot,name: url.deletingPathExtension().lastPathComponent,startBeat: start ?? 0,lengthBeats: min(4096,max(0.0625,length)),loop: false,audioPath: url.path,waveform: waveform)
        project.tracks[selectedTrack].clips.removeAll {$0.slot == selectedSlot}; project.tracks[selectedTrack].clips.append(clip)
        rebuild()
    }
    func importMIDI() {
        guard !recording else { error = "Finish recording before importing MIDI."; return }
        let panel = NSOpenPanel(); panel.allowedContentTypes = [UTType(filenameExtension: "mid") ?? .data]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let notes = try MIDIFile.read(Data(contentsOf: url)); guard notes.count <= 64 else { throw ProjectError.invalid }
            if !project.tracks.indices.contains(selectedTrack) || project.tracks[selectedTrack].kind != .midi { addTrack(.midi) }
            guard project.tracks[selectedTrack].kind == .midi else { throw ProjectError.invalid }
            project.tracks[selectedTrack].clips.removeAll {$0.slot == selectedSlot}
            let length = max(4,ceil((notes.map {$0.startBeat+$0.duration}.max() ?? 4)/4)*4)
            project.tracks[selectedTrack].clips.append(BeatClip(slot: selectedSlot,name: url.deletingPathExtension().lastPathComponent,lengthBeats: length,notes: notes)); rebuild()
        } catch { self.error = error.localizedDescription }
    }
    func exportMIDI() {
        guard let clip = selectedClip, !clip.notes.isEmpty else { error = "Select a MIDI clip with notes."; return }
        let panel = NSSavePanel(); panel.nameFieldStringValue = clip.name+".mid"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try MIDIFile.write(clip.notes,bpm: project.bpm).write(to: url,options: .atomic); status = "MIDI exported" } catch { self.error = error.localizedDescription }
    }
    func record() {
        guard !recordingPermissionPending else { return }
        if recording { endRecording(); return }
        guard project.tracks.indices.contains(selectedTrack), project.tracks[selectedTrack].kind == .audio,project.tracks[selectedTrack].armed else { error = "Select and arm an audio track before recording."; return }
        let requestedTrack = selectedTrack
        recordingPermissionPending = true
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] allowed in
            Task { @MainActor in
                guard let self else { return }
                self.recordingPermissionPending = false
                guard !self.recording, self.project.tracks.indices.contains(requestedTrack), self.project.tracks[requestedTrack].armed, self.project.tracks[requestedTrack].kind == .audio else { return }
                guard allowed else { self.error = "Allow microphone access in System Settings → Privacy & Security → Microphone."; return }
                do { guard let audio = self.host else { throw ProjectError.allocation }; self.recordingTrack = requestedTrack; self.recordingBeat = self.beat; _ = try audio.beginRecording(); self.recording = true; if !self.playing { self.play() }; self.status = "Recording microphone · press Record or Stop to finish" }
                catch { self.error = error.localizedDescription }
            }
        }
    }
    private func endRecording() {
        guard let url = host?.endRecording() else { recording = false; return }
        recording = false; selectedTrack = recordingTrack
        do { try installAudio(url,start: recordingBeat); status = "Recording added to track · save the project to collect its audio" }
        catch { self.error = error.localizedDescription }
    }
    func confirmClose() -> Bool { canDiscard() }
    private func canDiscard() -> Bool {
        guard !recording else { error = "Finish recording first."; return false }
        guard dirty else { return true }
        let alert = NSAlert(); alert.messageText = "Save changes to \(project.name)?"; alert.addButton(withTitle: "Save"); alert.addButton(withTitle: "Discard"); alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn { return saveProject() }
        return response == .alertSecondButtonReturn
    }
    func newProject() {
        guard canDiscard() else { return }; stop()
        let next = BeatProject(tracks: [BeatTrack(name: "Audio 1",kind: .audio),BeatTrack(name: "MIDI 1",kind: .midi,color: 1)])
        do { try host?.replace(next,base: nil); project = next; committed = next; documentURL = nil; selectedTrack = 0; selectedSlot = 0; dirty = false; past = []; future = [] }
        catch { self.error = error.localizedDescription }
    }
    func save() { _ = saveProject() }
    private func saveProject() -> Bool {
        guard !recording else { error = "Finish recording before saving."; return false }
        let url: URL
        if let existing = documentURL { url = existing }
        else { let panel = NSSavePanel(); panel.allowedContentTypes = [UTType(exportedAs: "com.mpaudio.beatmeat.project",conformingTo: .package)]; panel.nameFieldStringValue = project.name+".beatmeat"; panel.canCreateDirectories = true; guard panel.runModal() == .OK, let selected = panel.url else { return false }; url = selected }
        do { let saved = try ProjectIO.write(project,to: url,base: documentURL); project = saved; committed = saved; documentURL = url; dirty = false; past = []; future = []; status = "Saved · audio collected inside \(url.lastPathComponent)"; return true }
        catch { self.error = error.localizedDescription; return false }
    }
    func open() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = true; panel.treatsFilePackagesAsDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        openURL(url)
    }
    func openURL(_ url: URL) {
        guard canDiscard() else { return }
        do { let loaded = try ProjectIO.read(url); try host?.replace(loaded,base: url); project = loaded; committed = loaded; documentURL = url; selectedTrack = 0; selectedSlot = 0; dirty = false; past = []; future = []; playing = false; beat = 0; status = "Opened \(loaded.name)" }
        catch { self.error = error.localizedDescription }
    }
    func exportWAV() {
        let panel = NSSavePanel(); panel.nameFieldStringValue = project.name+".wav"; panel.allowedContentTypes = [.wav]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let snapshot = project, base = documentURL, gain = master
        status = "Rendering Arrangement…"
        Task {
            do { try await Task.detached { try AudioHost.export(snapshot,base: base,to: url,master: gain) }.value; status = "Exported 44.1 kHz float WAV · \(url.lastPathComponent)" }
            catch { self.error = error.localizedDescription }
        }
    }
}
