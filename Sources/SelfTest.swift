import Foundation
import AVFoundation

enum SelfTest {
    static func run(_ directory: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: directory,withIntermediateDirectories: true)
        let project = BeatProject.demo(); try project.validate()
        let package = directory.appendingPathComponent("self-test.beatmeat")
        let saved = try ProjectIO.write(project,to: package,base: nil)
        let restored = try ProjectIO.read(package)
        guard restored.tracks.count == 4, restored.tracks[0].clips[0].notes.count == 8 else { throw ProjectError.invalid }
        _ = try ProjectIO.write(saved,to: package,base: package)
        let midi = MIDIFile.write(project.tracks[0].clips[0].notes,bpm: project.bpm)
        let imported = try MIDIFile.read(midi)
        guard imported.count == 8 else { throw ProjectError.invalid }
        let export = directory.appendingPathComponent("self-test.wav")
        try AudioHost.export(restored,base: package,to: export,master: 0.8)
        let audio = try AVAudioFile(forReading: export)
        guard audio.length > 44100, let buffer = AVAudioPCMBuffer(pcmFormat: audio.processingFormat,frameCapacity: 44100) else { throw ProjectError.invalid }
        try audio.read(into: buffer)
        guard let left = buffer.floatChannelData?[0], (0..<Int(buffer.frameLength)).contains(where: {abs(left[$0]) > 0.001}) else { throw ProjectError.invalid }
        let result: [String:Any] = ["status":"passed","projectRoundTrip":true,"projectOverwrite":true,"midiRoundTrip":true,"offlineAudioExport":true,"audioFrames":audio.length,"uiInspected":false,"deviceRecordingTested":false]
        try JSONSerialization.data(withJSONObject: result,options: [.prettyPrinted,.sortedKeys]).write(to: directory.appendingPathComponent("validation.json"))
    }
}
