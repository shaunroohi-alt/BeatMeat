import Foundation

enum TrackKind: String, Codable, CaseIterable, Sendable { case audio, midi }
enum WorkspaceMode: String, CaseIterable { case session = "Session", arrangement = "Arrangement" }
struct BeatNote: Identifiable, Codable, Sendable {
    var id = UUID()
    var pitch: Int
    var velocity: Double = 0.7
    var startBeat: Double
    var duration: Double = 0.5
}
struct BeatClip: Identifiable, Codable, Sendable {
    var id = UUID()
    var slot: Int
    var name: String
    var startBeat: Double = 0
    var lengthBeats: Double = 4
    var loop = true
    var audioPath: String? = nil
    var waveform: [Float] = []
    var notes: [BeatNote] = []
}
struct BeatTrack: Identifiable, Codable, Sendable {
    var id = UUID()
    var name: String
    var kind: TrackKind
    var color: Int = 0
    var gain: Double = 0.75
    var pan: Double = 0
    var mute = false
    var solo = false
    var armed = false
    var send: Double = 0
    var cutoff: Double = 20000
    var clips: [BeatClip] = []
}
struct BeatProject: Codable, Sendable {
    var version = 1
    var name = "Untitled"
    var bpm: Double = 120
    var loopEnabled = true
    var loopStart: Double = 0
    var loopEnd: Double = 16
    var tracks: [BeatTrack] = []
    static func demo() -> BeatProject {
        let bass = (0..<8).map { BeatNote(pitch: [36,36,43,39,36,46,43,34][$0], startBeat: Double($0)*0.5, duration: 0.35) }
        let harmony = [48,55,60].map { BeatNote(pitch: $0, velocity: 0.3, startBeat: 0, duration: 3.8) }
        return BeatProject(name: "First cut", tracks: [
            BeatTrack(name: "01 · Bass", kind: .midi, color: 0, clips: [BeatClip(slot: 0, name: "After hours", notes: bass)]),
            BeatTrack(name: "02 · Chords", kind: .midi, color: 1, gain: 0.45, pan: -0.15, clips: [BeatClip(slot: 0, name: "Open space", notes: harmony)]),
            BeatTrack(name: "03 · Audio", kind: .audio, color: 2),
            BeatTrack(name: "04 · Texture", kind: .audio, color: 3)])
    }
    func validate() throws {
        guard version == 1, !tracks.isEmpty, bpm.isFinite, (20...300).contains(bpm), loopStart.isFinite, loopEnd.isFinite,
              loopStart >= 0, loopEnd > loopStart, loopEnd <= 100_000, tracks.count <= 16, Set(tracks.map(\.id)).count == tracks.count else { throw ProjectError.invalid }
        for track in tracks {
            guard track.gain.isFinite, (0...2).contains(track.gain), track.pan.isFinite, (-1...1).contains(track.pan),
                  track.send.isFinite, (0...1).contains(track.send), track.cutoff.isFinite, (20...20000).contains(track.cutoff), track.clips.count <= 8, Set(track.clips.map(\.id)).count == track.clips.count,
                  Set(track.clips.map(\.slot)).count == track.clips.count else { throw ProjectError.invalid }
            for clip in track.clips {
                guard (0..<8).contains(clip.slot), clip.startBeat.isFinite, clip.startBeat >= 0, clip.startBeat <= 100_000,
                      clip.lengthBeats.isFinite, (0.0625...4096).contains(clip.lengthBeats), clip.notes.count <= 64,
                      Set(clip.notes.map(\.id)).count == clip.notes.count, clip.waveform.count <= 4096, clip.waveform.allSatisfy({$0.isFinite}) else { throw ProjectError.invalid }
                for note in clip.notes {
                    guard (0...127).contains(note.pitch), note.velocity.isFinite, (0...1).contains(note.velocity),
                          note.startBeat.isFinite, note.startBeat >= 0, note.startBeat <= 4096, note.duration.isFinite, note.duration > 0, note.duration <= 4096 else { throw ProjectError.invalid }
                }
            }
        }
    }
}
enum ProjectError: LocalizedError {
    case invalid, unsafeMedia, audioLimit, allocation
    var errorDescription: String? {
        switch self {
        case .invalid: return "This project contains unsupported or invalid track, clip, or transport data."
        case .unsafeMedia: return "Project audio must be stored inside its Media folder."
        case .audioLimit: return "The audio exceeds this development build's memory limit. Use shorter files (maximum 256 MiB decoded audio across the project)."
        case .allocation: return "The audio engine could not allocate its buffers."
        }
    }
}
enum ProjectIO {
    static func mediaURL(_ path: String, base: URL?) throws -> URL {
        if path.hasPrefix("/") { return URL(fileURLWithPath: path) }
        guard let base else { throw ProjectError.unsafeMedia }
        let url = base.appendingPathComponent(path).resolvingSymlinksInPath()
        let projectRoot = base.resolvingSymlinksInPath().path + "/"
        let mediaRoot = base.appendingPathComponent("Media").resolvingSymlinksInPath().path
        guard mediaRoot.hasPrefix(projectRoot), url.path.hasPrefix(mediaRoot + "/") else { throw ProjectError.unsafeMedia }
        return url
    }
    static func read(_ url: URL) throws -> BeatProject {
        let metadata = url.appendingPathComponent("Project.json")
        let size = try metadata.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= 8_000_000 else { throw ProjectError.invalid }
        let project = try JSONDecoder().decode(BeatProject.self, from: Data(contentsOf: metadata))
        try project.validate()
        for track in project.tracks { for clip in track.clips { if let path = clip.audioPath {
            guard !path.hasPrefix("/") else { throw ProjectError.unsafeMedia }
            _ = try mediaURL(path, base: url)
        } } }
        return project
    }
    static func write(_ project: BeatProject, to url: URL, base: URL?) throws -> BeatProject {
        try project.validate()
        let fm = FileManager.default
        let temp = url.deletingLastPathComponent().appendingPathComponent(".beatmeat-save-"+UUID().uuidString)
        try fm.createDirectory(at: temp.appendingPathComponent("Media"), withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: temp) }
        var saved = project
        for t in saved.tracks.indices { for c in saved.tracks[t].clips.indices {
            guard let path = saved.tracks[t].clips[c].audioPath else { continue }
            let source = try mediaURL(path, base: base)
            let filename = saved.tracks[t].clips[c].id.uuidString + "." + source.pathExtension
            let relative = "Media/"+filename
            try fm.copyItem(at: source, to: temp.appendingPathComponent(relative))
            saved.tracks[t].clips[c].audioPath = relative
        } }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted,.sortedKeys]
        try encoder.encode(saved).write(to: temp.appendingPathComponent("Project.json"), options: .atomic)
        if fm.fileExists(atPath: url.path) { _ = try fm.replaceItemAt(url, withItemAt: temp) }
        else { try fm.moveItem(at: temp, to: url) }
        return saved
    }
}
